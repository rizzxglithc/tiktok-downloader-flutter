import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/download_item.dart';
import '../providers/history_provider.dart';
import '../widgets/custom_toast.dart';
import '../widgets/glass_card.dart';
import 'video_viewer_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final items = historyProvider.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Unduhan'),
        actions: [
          if (historyProvider.totalCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
              tooltip: 'Hapus Semua Riwayat',
              onPressed: () => _confirmClearAll(context, historyProvider),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Search TextField
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => historyProvider.setSearchQuery(val),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            cursorColor: AppColors.primary,
                            decoration: const InputDecoration(
                              hintText: 'Cari judul atau kreator...',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              historyProvider.setSearchQuery('');
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  Row(
                    children: [
                      _filterChip(
                        label: 'Semua',
                        isSelected: historyProvider.selectedFilter == null,
                        onTap: () => historyProvider.setFilter(null),
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: 'Video MP4',
                        icon: Icons.videocam_rounded,
                        isSelected: historyProvider.selectedFilter == DownloadType.video,
                        onTap: () => historyProvider.setFilter(DownloadType.video),
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: 'Audio MP3',
                        icon: Icons.audiotrack_rounded,
                        isSelected: historyProvider.selectedFilter == DownloadType.audio,
                        onTap: () => historyProvider.setFilter(DownloadType.audio),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // History List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: AppColors.textMuted,
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Belum Ada Riwayat',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'File yang berhasil Anda download akan tersimpan di sini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _historyItemCard(context, item, historyProvider);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 14,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyItemCard(
    BuildContext context,
    DownloadItem item,
    HistoryProvider historyProvider,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      onTap: () => _handleOpenItem(context, item, historyProvider),
      child: Row(
        children: [
          // Thumbnail / Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: AppColors.surface,
              child: item.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                        item.isVideo ? Icons.movie_rounded : Icons.audiotrack_rounded,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      item.isVideo ? Icons.movie_rounded : Icons.audiotrack_rounded,
                      color: AppColors.primary,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Title, format & date
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
                Text(
                  item.author,
                  style: const TextStyle(
                    color: AppColors.textAccent,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.isVideo
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isVideo ? 'MP4' : 'MP3',
                        style: TextStyle(
                          color: item.isVideo ? AppColors.primary : AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.formatRelativeDate(item.createdAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Popup Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.glassBorder),
            ),
            onSelected: (value) {
              if (value == 'open') {
                _handleOpenItem(context, item, historyProvider);
              } else if (value == 'share') {
                historyProvider.shareFile(item);
              } else if (value == 'delete') {
                _confirmDeleteItem(context, item, historyProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 10),
                    Text('Buka File', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, color: AppColors.accent, size: 18),
                    SizedBox(width: 10),
                    Text('Bagikan', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                    SizedBox(width: 10),
                    Text('Hapus', style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleOpenItem(
    BuildContext context,
    DownloadItem item,
    HistoryProvider historyProvider,
  ) {
    if (item.isVideo && item.filePath.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoViewerPage(
            filePath: item.filePath,
            title: item.title,
          ),
        ),
      );
    } else {
      historyProvider.openFile(item);
    }
  }

  void _confirmDeleteItem(
    BuildContext context,
    DownloadItem item,
    HistoryProvider historyProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Hapus Item?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'Item ini dan file yang tersimpan di memori akan dihapus.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              historyProvider.deleteItem(item.id, deleteFile: true);
              CustomToast.show(context, message: 'Item berhasil dihapus.', type: ToastType.info);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, HistoryProvider historyProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Hapus Semua Riwayat?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'Semua daftar unduhan dan file yang tersimpan akan dibersihkan.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              historyProvider.clearAll(deleteFiles: true);
              CustomToast.show(context, message: 'Semua riwayat dibersihkan.', type: ToastType.info);
            },
            child: const Text('Hapus Semua', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
