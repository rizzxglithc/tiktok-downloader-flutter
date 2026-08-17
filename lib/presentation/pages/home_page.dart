import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/url_validator.dart';
import '../../domain/entities/tiktok_video.dart';
import '../../services/clipboard_service.dart';
import '../../services/quick_share_service.dart';
import '../providers/tiktok_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/custom_toast.dart';
import 'video_result_page.dart';
import 'video_viewer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  String? _errorMessage;
  MediaPlatform? _detectedPlatform;
  StreamSubscription<String>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
    _checkClipboard();
    _initQuickShare();
  }

  void _initQuickShare() {
    QuickShareService.initialize(onUrlReceived: (url) {
      if (mounted && url.isNotEmpty) {
        setState(() {
          _urlController.text = url;
          _errorMessage = null;
        });
        final platform = UrlValidator.detectPlatform(url) ?? MediaPlatform.universal;
        final platformName = UrlValidator.getPlatformName(platform);
        CustomToast.showInfo(context, 'Menerima tautan $platformName dari menu Bagikan 🚀');
        _handleDownload(autoProcess: true);
      }
    });

    _shareSubscription = QuickShareService.onSharedUrlReceived.listen((url) {
      if (mounted && url.isNotEmpty) {
        setState(() {
          _urlController.text = url;
          _errorMessage = null;
        });
        _handleDownload(autoProcess: true);
      }
    });
  }

  void _onUrlChanged() {
    final text = _urlController.text.trim();
    final platform = UrlValidator.detectPlatform(text);
    if (platform != _detectedPlatform) {
      setState(() {
        _detectedPlatform = platform;
        if (platform != null) _errorMessage = null;
      });
    }
  }

  Future<void> _checkClipboard() async {
    final clipText = await ClipboardService.getClipboardText();
    final extracted = UrlValidator.cleanAndExtractUrl(clipText);
    if (extracted != null && extracted.isNotEmpty && mounted) {
      setState(() {
        _urlController.text = extracted;
      });
      final platform = UrlValidator.detectPlatform(extracted) ?? MediaPlatform.universal;
      final platformName = UrlValidator.getPlatformName(platform);
      CustomToast.showInfo(context, 'Tautan $platformName terdeteksi dari papan klip');
    }
  }

  Future<void> _handlePaste() async {
    final text = await ClipboardService.getClipboardText();
    final extracted = UrlValidator.cleanAndExtractUrl(text) ?? text.trim();
    if (extracted.isNotEmpty) {
      setState(() {
        _urlController.text = extracted;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleDownload({bool autoProcess = false}) async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Masukkan URL media sosial untuk diunduh');
      return;
    }

    if (!UrlValidator.isValidUrl(url)) {
      setState(() => _errorMessage = 'Format URL tidak valid. Masukkan tautan publik yang didukung.');
      return;
    }

    setState(() => _errorMessage = null);
    FocusScope.of(context).unfocus();

    final tiktokProvider = context.read<TikTokProvider>();
    final success = await tiktokProvider.fetchVideoInfo(url);

    if (success && tiktokProvider.currentVideo != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoResultPage(video: tiktokProvider.currentVideo!),
        ),
      );
    } else if (mounted) {
      final err = tiktokProvider.errorMessage;
      CustomToast.showError(
        context,
        (err != null && err.isNotEmpty) ? err : 'Gagal memproses media. Pastikan tautan bersifat publik.',
      );
    }
  }

  IconData _getPlatformIcon(MediaPlatform platform) {
    switch (platform) {
      case MediaPlatform.tiktok:
        return Icons.music_video_rounded;
      case MediaPlatform.instagram:
        return Icons.camera_alt_rounded;
      case MediaPlatform.facebook:
        return Icons.facebook_rounded;
      case MediaPlatform.twitter:
        return Icons.alternate_email_rounded;
      case MediaPlatform.youtube:
        return Icons.play_circle_fill_rounded;
      case MediaPlatform.threads:
        return Icons.forum_rounded;
      case MediaPlatform.capcut:
        return Icons.content_cut_rounded;
      case MediaPlatform.spotify:
        return Icons.headphones_rounded;
      case MediaPlatform.soundcloud:
        return Icons.graphic_eq_rounded;
      case MediaPlatform.pinterest:
        return Icons.push_pin_rounded;
      case MediaPlatform.applemusic:
        return Icons.music_note_rounded;
      case MediaPlatform.douyin:
        return Icons.video_library_rounded;
      case MediaPlatform.snackvideo:
        return Icons.movie_creation_rounded;
      case MediaPlatform.kuaishou:
        return Icons.flash_on_rounded;
      case MediaPlatform.universal:
        return Icons.link_rounded;
    }
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiktokProvider = context.watch<TikTokProvider>();
    final historyProvider = context.watch<HistoryProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(isCompact ? 14 : 20, 16, isCompact ? 14 : 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with App Logo & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight, width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/app_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MYDOWNLOADER',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                          Text(
                            'Universal Downloader',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.share_rounded, color: Colors.white, size: 11),
                        SizedBox(width: 5),
                        Text(
                          'Quick Share Aktif',
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Headline
              Text(
                'Unduh Video, Slide Foto\n& Audio Tanpa Batas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 22 : 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.6,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dukungan penuh untuk TikTok, Instagram, Facebook, Twitter/X, YouTube, Threads, CapCut, Spotify & lainnya tanpa watermark.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // 3. Main Input Card with Dynamic Auto-Detect
              GlassCard(
                padding: EdgeInsets.all(isCompact ? 14 : 18),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassTextField(
                      controller: _urlController,
                      hintText: 'Tempel link atau pilih Bagikan ke MyDownloader...',
                      errorText: _errorMessage,
                      prefixIcon: const Icon(Icons.link_rounded, color: AppColors.textMuted, size: 20),
                      suffixIcon: _urlController.text.isEmpty
                          ? IconButton(
                              icon: const Icon(Icons.content_paste_rounded, color: Colors.white, size: 20),
                              tooltip: 'Tempel Tautan',
                              onPressed: _handlePaste,
                            )
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                _urlController.clear();
                                setState(() => _errorMessage = null);
                              },
                            ),
                      onSubmitted: (_) => _handleDownload(),
                    ),

                    // Dynamic Auto-Detected Platform Pill
                    if (_detectedPlatform != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPlatformIcon(_detectedPlatform!),
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Platform Terdeteksi: ${UrlValidator.getPlatformName(_detectedPlatform!)}',
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    GlassButton(
                      text: 'Proses Media',
                      icon: Icons.download_rounded,
                      isLoading: tiktokProvider.isLoading,
                      onPressed: _handleDownload,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 4. Supported Platforms Badges Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPlatformBadge(Icons.music_video_rounded, 'TikTok'),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(Icons.camera_alt_rounded, 'Instagram'),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(Icons.facebook_rounded, 'Facebook'),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(Icons.alternate_email_rounded, 'Twitter / X'),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(Icons.play_circle_fill_rounded, 'YouTube'),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(Icons.forum_rounded, 'Threads'),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(Icons.content_cut_rounded, 'CapCut'),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(Icons.headphones_rounded, 'Spotify'),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(Icons.graphic_eq_rounded, 'SoundCloud'),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(Icons.music_note_rounded, 'Apple Music'),
                    const SizedBox(width: 8),
                    _buildPlatformBadge(Icons.push_pin_rounded, 'Pinterest'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Quick Features
              Row(
                children: [
                  Expanded(
                    child: _buildFeaturePill(Icons.share_rounded, 'Quick Share', 'Menu Bagikan HP'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeaturePill(Icons.photo_library_rounded, 'Slide Foto', 'Carousel HD'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeaturePill(Icons.audiotrack_rounded, 'Audio MP3', 'Full Bitrate'),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // 6. Recent Downloads Section (Animated & Responsive)
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: historyProvider.allItems.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Unduhan Terakhir',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                '${historyProvider.allItems.length} file',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 130,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: historyProvider.allItems.take(8).length,
                              separatorBuilder: (context, index) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final item = historyProvider.allItems[index];
                                return GestureDetector(
                                  onTap: () {
                                    if (item.isVideo && item.filePath.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VideoViewerPage(
                                            videoUrl: item.filePath,
                                            title: item.title,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 105,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.border, width: 1),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: item.thumbnailUrl.isNotEmpty
                                              ? Image.network(
                                                  item.thumbnailUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    color: AppColors.surfaceHover,
                                                    child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                                                  ),
                                                )
                                              : Container(
                                                  color: AppColors.surfaceHover,
                                                  child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted),
                                                ),
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          right: 8,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                item.isPhotos
                                                    ? Icons.photo_library_rounded
                                                    : (item.isVideo ? Icons.play_arrow_rounded : Icons.audiotrack_rounded),
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String title, String subtitle) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      borderRadius: 14,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
