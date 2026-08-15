import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/tiktok_video.dart';
import '../providers/download_provider.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/video_preview_player.dart';
import '../widgets/custom_toast.dart';

class VideoResultPage extends StatelessWidget {
  final TikTokVideo video;

  const VideoResultPage({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Embedded Video Player Preview
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: VideoPreviewPlayer(
                  videoUrl: video.videoUrl,
                  thumbnailUrl: video.coverUrl,
                  title: video.title,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Author Profile & Caption Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: video.authorAvatar.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: video.authorAvatar,
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: AppColors.surfaceHover),
                                errorWidget: (context, url, error) => Container(
                                  width: 42,
                                  height: 42,
                                  color: AppColors.surfaceHover,
                                  child: const Icon(Icons.person_rounded, color: AppColors.textMuted),
                                ),
                              )
                            : Container(
                                width: 42,
                                height: 42,
                                color: AppColors.surfaceHover,
                                child: const Icon(Icons.person_rounded, color: AppColors.textMuted),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.authorName.isNotEmpty ? video.authorName : video.authorUsername,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${video.authorUsername}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          Formatters.formatDuration(video.durationSeconds),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (video.title.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(Icons.favorite_rounded, Formatters.formatCompactNumber(video.likesCount)),
                      _buildMetric(Icons.chat_bubble_rounded, Formatters.formatCompactNumber(video.commentsCount)),
                      _buildMetric(Icons.share_rounded, Formatters.formatCompactNumber(video.sharesCount)),
                      _buildMetric(Icons.play_arrow_rounded, Formatters.formatCompactNumber(video.viewsCount)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Download Section Header
            const Text(
              'Opsi Unduhan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),

            // 4. Download Buttons
            // Button A: HD MP4 No-Watermark
            if (video.hasHd) ...[
              GlassButton(
                text: 'Unduh Video MP4 (Full HD)',
                icon: Icons.hd_rounded,
                onPressed: () async {
                  final started = await downloadProvider.startDownload(
                    video: video,
                    isVideo: true,
                    isHd: true,
                    context: context,
                  );
                  if (started && context.mounted) {
                    CustomToast.showSuccess(context, 'Pengunduhan Full HD dimulai');
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],

            // Button B: Standard MP4
            GlassButton(
              text: 'Unduh Video MP4 (No Watermark)',
              icon: Icons.download_rounded,
              isSecondary: video.hasHd,
              onPressed: () async {
                final started = await downloadProvider.startDownload(
                  video: video,
                  isVideo: true,
                  isHd: false,
                  context: context,
                );
                if (started && context.mounted) {
                  CustomToast.showSuccess(context, 'Pengunduhan video dimulai');
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 10),

            // Button C: Audio MP3
            if (video.hasAudio)
              GlassButton(
                text: 'Unduh Audio MP3 (Musik)',
                icon: Icons.music_note_rounded,
                isSecondary: true,
                onPressed: () async {
                  final started = await downloadProvider.startDownload(
                    video: video,
                    isVideo: false,
                    isHd: false,
                    context: context,
                  );
                  if (started && context.mounted) {
                    CustomToast.showSuccess(context, 'Pengunduhan Audio MP3 dimulai');
                    Navigator.pop(context);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
