import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../providers/history_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_toast.dart';
import 'video_viewer_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleOpenMedia(BuildContext context, String savedPath, String title, bool isVideo) {
    if (savedPath.isEmpty) {
      CustomToast.showError(context, 'Path file tidak valid.');
      return;
    }

    if (isVideo && File(savedPath).existsSync()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoViewerPage(
            videoUrl: savedPath,
            title: title,
          ),
        ),
      );
    } else {
      OpenFilex.open(savedPath).then((result) {
        if (result.type != ResultType.done && mounted) {
          CustomToast.showInfo(context, 'Membuka file: $savedPath');
        }
      });
    }
  }

  void _handleShare(String savedPath, String title) {
    if (savedPath.isNotEmpty && File(savedPath).existsSync()) {
      Share.shareXFiles([XFile(savedPath)], text: 'Dibagikan via TikTok Downloader Pro: $title');
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final items = historyProvider.filteredItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Unduhan'),
        automaticallyImplyLeading: false,
        actions: [
          if (historyProvider.allItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.textMuted, size: 22),
              tooltip: 'Bersihkan Riwayat',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF18181B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Hapus Semua Riwayat?', style: TextStyle(color: Colors.white, fontSize: 16)),
                    content: const Text(
                      'Riwayat unduhan akan dibersihkan dari daftar aplikasi.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          historyProvider.clearAll();
                          CustomToast.showInfo(context, 'Riwayat berhasil dibersihkan');
                        },
                        child: const Text('Hapus', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Search Input
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => historyProvider.setSearchQuery(value),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Cari riwayat unduhan...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                historyProvider.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Buttons
                Row(
                  children: [
                    _buildFilterChip(
                      label: 'Semua (${historyProvider.allItems.length})',
                      isSelected: historyProvider.selectedFilter == HistoryFilter.all,
                      onTap: () => historyProvider.setFilter(HistoryFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Video MP4',
                      isSelected: historyProvider.selectedFilter == HistoryFilter.video,
                      onTap: () => historyProvider.setFilter(HistoryFilter.video),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Audio MP3',
                      isSelected: historyProvider.selectedFilter == HistoryFilter.audio,
                      onTap: () => historyProvider.setFilter(HistoryFilter.audio),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. History List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: AppColors.textMuted,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Belum ada riwayat unduhan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'File yang berhasil diunduh akan otomatis tercatat di sini',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 16,
                        onTap: () => _handleOpenMedia(context, item.savedPath, item.title, item.isVideo),
                        child: Row(
                          children: [
                            // Thumbnail / Icon
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 52,
                                height: 52,
                                color: const Color(0xFF1E1E22),
                                child: item.thumbnailUrl.isNotEmpty
                                    ? Image.network(
                                        item.thumbnailUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          item.isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded,
                                          color: AppColors.textMuted,
                                        ),
                                      )
                                    : Icon(
                                        item.isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded,
                                        color: AppColors.textMuted,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title.isNotEmpty ? item.title : 'TikTok Download',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.authorName} • ${Formatters.formatBytes(item.fileSizeBytes)}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Formatters.formatDate(item.downloadedAt),
                                    style: const TextStyle(color: AppColors.textDisabled, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // Actions (Share & Delete)
                            IconButton(
                              icon: const Icon(Icons.share_rounded, color: AppColors.textSecondary, size: 18),
                              onPressed: () => _handleShare(item.savedPath, item.title),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                historyProvider.deleteItem(item.id);
                                CustomToast.showInfo(context, 'Item dihapus dari riwayat');
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
