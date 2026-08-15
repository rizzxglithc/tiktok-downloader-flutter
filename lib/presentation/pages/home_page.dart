import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/url_validator.dart';
import '../../domain/entities/tiktok_video.dart';
import '../../services/clipboard_service.dart';
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

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
    _checkClipboard();
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
      final platformName = _detectedPlatform == MediaPlatform.instagram ? 'Instagram' : 'TikTok';
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

  Future<void> _handleDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Masukkan URL TikTok atau Instagram');
      return;
    }

    if (!UrlValidator.isValidUrl(url)) {
      setState(() => _errorMessage = 'Format URL tidak valid. Pastikan tautan TikTok / Instagram.');
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

  @override
  void dispose() {
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
                        Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 5),
                        Text(
                          'Slide & HD',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
                'Dukungan penuh untuk TikTok & Instagram: Unduh Video HD tanpa watermark, Slide Foto Carousel, dan Musik MP3.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // 3. Main Input Card with Auto-Detect Badge
              GlassCard(
                padding: EdgeInsets.all(isCompact ? 14 : 18),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassTextField(
                      controller: _urlController,
                      hintText: 'Tempel link TikTok atau Instagram...',
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

                    // Auto-Detected Platform Pill
                    if (_detectedPlatform != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _detectedPlatform == MediaPlatform.instagram
                                  ? Icons.camera_alt_rounded
                                  : Icons.music_video_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _detectedPlatform == MediaPlatform.instagram
                                  ? 'Platform Terdeteksi: Instagram'
                                  : 'Platform Terdeteksi: TikTok',
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

              // 4. Quick Features Cards
              Row(
                children: [
                  Expanded(
                    child: _buildFeaturePill(Icons.photo_library_rounded, 'Slide Foto', 'Carousel HD'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeaturePill(Icons.movie_filter_rounded, 'Reels & MP4', 'No Watermark'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeaturePill(Icons.audiotrack_rounded, 'Audio MP3', 'Full Bitrate'),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // 5. Recent Downloads Section
              if (historyProvider.allItems.isNotEmpty) ...[
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
            ],
          ),
        ),
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
