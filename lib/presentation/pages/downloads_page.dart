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
    final activeDownloads = downloadProvider.activeDownloads;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Unduhan Aktif'),
        automaticallyImplyLeading: false,
      ),
      body: activeDownloads.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.cloud_download_outlined,
                      color: AppColors.textMuted,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak ada proses unduhan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Media yang sedang diproses akan tampil di sini',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              itemCount: activeDownloads.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final state = activeDownloads[index];
                final item = state.item;

                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.isPhotos
                                  ? Icons.photo_library_rounded
                                  : (item.isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title.isNotEmpty ? item.title : 'MyDownloader Media',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.isPhotos
                                      ? 'Menyimpan ${item.mediaCount} Foto ke Galeri'
                                      : item.author,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                            onPressed: () => downloadProvider.cancelDownload(item.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GradientProgressBar(
                        progress: state.progress,
                        height: 5,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.isPhotos
                                ? '${(state.progress * 100).toStringAsFixed(0)}% (${(state.progress * item.mediaCount).toInt()} / ${item.mediaCount} Foto)'
                                : '${(state.progress * 100).toStringAsFixed(1)}% (${Formatters.formatBytes(state.downloadedBytes)} / ${Formatters.formatBytes(state.totalBytes)})',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          if (!item.isPhotos)
                            Text(
                              state.speedString,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
