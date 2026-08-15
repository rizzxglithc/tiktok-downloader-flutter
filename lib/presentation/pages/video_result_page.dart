import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/tiktok_video.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_toast.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/video_preview_player.dart';

class VideoResultPage extends StatelessWidget {
  final TikTokVideo video;

  const VideoResultPage({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Video TikTok'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Video Preview Player
              VideoPreviewPlayer(
                videoUrl: video.bestVideoUrl,
                coverUrl: video.coverUrl,
              ),
              const SizedBox(height: 18),

              // 2. Author Profile Card
              GlassCard(
                padding: const EdgeInsets.all(14),
                borderRadius: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surface,
                      backgroundImage: video.authorAvatar.isNotEmpty
                          ? CachedNetworkImageProvider(video.authorAvatar)
                          : null,
                      child: video.authorAvatar.isEmpty
                          ? const Icon(Icons.person_rounded, color: AppColors.textMuted)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.authorName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            video.authorUsername,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Caption & Video Stats
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 14),

                    // Metrics Grid (Duration, Resolution, Likes, Views)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricItem(
                          icon: Icons.timer_outlined,
                          label: 'Durasi',
                          value: Formatters.formatDuration(video.durationSeconds),
                        ),
                        _metricItem(
                          icon: Icons.aspect_ratio_rounded,
                          label: 'Resolusi',
                          value: '${video.width}x${video.height}',
                        ),
                        if (video.fileSize > 0)
                          _metricItem(
                            icon: Icons.data_usage_rounded,
                            label: 'Ukuran',
                            value: Formatters.formatBytes(video.fileSize),
                          ),
                        _metricItem(
                          icon: Icons.favorite_border_rounded,
                          label: 'Suka',
                          value: Formatters.formatCompactNumber(video.likesCount),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 4. Download Options Section
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Opsi Unduhan',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // Download Video MP4 Button
              GlassButton(
                text: video.hasHd
                    ? 'Download Video MP4 (HD No Watermark)'
                    : 'Download Video MP4 (No Watermark)',
                icon: Icons.video_file_rounded,
                gradient: AppColors.primaryGradient,
                onPressed: () => _handleDownload(
                  context: context,
                  type: DownloadType.video,
                  isHd: settingsProvider.hdByDefault,
                ),
              ),
              const SizedBox(height: 12),

              // Download Audio MP3 Button (if available)
              if (video.hasAudio)
                GlassButton(
                  text: 'Download Audio MP3 (Original Sound)',
                  icon: Icons.audiotrack_rounded,
                  isSecondary: true,
                  backgroundColor: AppColors.surface,
                  onPressed: () => _handleDownload(
                    context: context,
                    type: DownloadType.audio,
                    isHd: false,
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _handleDownload({
    required BuildContext context,
    required DownloadType type,
    required bool isHd,
  }) async {
    final downloadProvider = context.read<DownloadProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    CustomToast.show(
      context,
      message: 'Memulai pengunduhan ${type == DownloadType.video ? "Video MP4" : "Audio MP3"}...',
      type: ToastType.info,
    );

    try {
      await downloadProvider.startDownload(
        video: video,
        type: type,
        isHd: isHd,
        autoSaveToGallery: settingsProvider.autoSaveToGallery,
        historyProvider: historyProvider,
      );

      if (context.mounted) {
        CustomToast.show(
          context,
          message: '${type == DownloadType.video ? "Video" : "Audio"} berhasil disimpan!',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(
          context,
          message: 'Pengunduhan gagal: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }
}
