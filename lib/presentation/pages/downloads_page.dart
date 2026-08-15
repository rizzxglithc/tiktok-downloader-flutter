import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../providers/download_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_progress_bar.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final activeList = downloadProvider.activeDownloads;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Unduhan Aktif'),
      ),
      body: SafeArea(
        child: activeList.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.downloading_rounded,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Tidak Ada Unduhan Berjalan',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Video atau audio yang sedang Anda download akan muncul di sini secara real-time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: activeList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = activeList[index];
                  final speed = downloadProvider.getSpeed(item.id);
                  final speedText = speed > 0 ? '${Formatters.formatBytes(speed.toInt())}/s' : 'Menyiapkan...';

                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 56,
                                height: 56,
                                color: AppColors.surface,
                                child: item.thumbnailUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.thumbnailUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(color: AppColors.surface),
                                        errorWidget: (context, url, error) => const Icon(
                                          Icons.movie_rounded,
                                          color: AppColors.textMuted,
                                        ),
                                      )
                                    : const Icon(Icons.movie_rounded, color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Title & Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.isVideo
                                              ? AppColors.primary.withOpacity(0.15)
                                              : AppColors.secondary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.isVideo ? 'MP4 VIDEO' : 'MP3 AUDIO',
                                          style: TextStyle(
                                            color: item.isVideo ? AppColors.primary : AppColors.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        speedText,
                                        style: const TextStyle(
                                          color: AppColors.textAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Cancel Button
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
                              onPressed: () {
                                downloadProvider.cancelDownload(item.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Progress Bar
                        GradientProgressBar(
                          progress: item.progress,
                          height: 6,
                        ),
                        const SizedBox(height: 8),

                        // Progress metrics
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(item.progress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              item.totalBytes > 0
                                  ? '${Formatters.formatBytes(item.downloadedBytes)} / ${Formatters.formatBytes(item.totalBytes)}'
                                  : Formatters.formatBytes(item.downloadedBytes),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
