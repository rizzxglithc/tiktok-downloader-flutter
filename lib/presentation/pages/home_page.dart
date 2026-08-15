import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    final clipText = await ClipboardService.getTikTokUrlFromClipboard();
    if (clipText != null && clipText.isNotEmpty && mounted) {
      setState(() {
        _urlController.text = clipText;
      });
      CustomToast.showInfo(context, 'Tautan TikTok otomatis disalin dari papan klip');
    }
  }

  Future<void> _handlePaste() async {
    final text = await ClipboardService.getClipboardText();
    if (text.isNotEmpty) {
      setState(() {
        _urlController.text = text;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Masukkan URL TikTok terlebih dahulu');
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
        (err != null && err.isNotEmpty) ? err : 'Gagal mengambil video TikTok. Periksa tautan Anda.',
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiktokProvider = context.watch<TikTokProvider>();
    final historyProvider = context.watch<HistoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Logo & Brand
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight, width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/app_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.play_circle_fill_rounded,
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
                            'TIKTOK DOWNLOADER',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Pro Edition',
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
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 5),
                        Text(
                          'No Watermark',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 2. Headline
              const Text(
                'Unduh Video & Audio\nKualitas Penuh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.6,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tempel tautan video TikTok untuk mengunduh MP4 HD atau MP3 langsung ke galeri.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // 3. Main Input Card
              GlassCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                child: Column(
                  children: [
                    GlassTextField(
                      controller: _urlController,
                      hintText: 'https://vt.tiktok.com/... atau tiktok.com/@...',
                      errorText: _errorMessage,
                      prefixIcon: const Icon(Icons.link_rounded, color: AppColors.textMuted, size: 20),
                      suffixIcon: _urlController.text.isEmpty
                          ? IconButton(
                              icon: const Icon(Icons.content_paste_rounded, color: Colors.white, size: 20),
                              tooltip: 'Tempel Tautan',
                              onPressed: _handlePaste,
                            )
                          : null,
                      onSubmitted: (_) => _handleDownload(),
                    ),
                    const SizedBox(height: 14),
                    GlassButton(
                      text: 'Ambil Video',
                      icon: Icons.search_rounded,
                      isLoading: tiktokProvider.isLoading,
                      onPressed: _handleDownload,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 4. Quick Features Cards
              Row(
                children: [
                  Expanded(
                    child: _buildFeaturePill(Icons.high_quality_rounded, 'Full HD 1080p', 'Kualitas tinggi'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFeaturePill(Icons.audiotrack_rounded, 'Audio MP3', 'Original sound'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 5. Recent Downloads Header
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
                const SizedBox(height: 14),

                // Recent items horizontal list
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: historyProvider.allItems.take(5).length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
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
                          width: 110,
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
                                          child: const Icon(Icons.movie_outlined, color: AppColors.textMuted),
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
                                      item.isVideo ? Icons.play_arrow_rounded : Icons.audiotrack_rounded,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 14,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
