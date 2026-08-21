import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/download_item.dart';
import '../../services/media_storage_service.dart';
import '../providers/history_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_toast.dart';
import 'video_viewer_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

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

  void _handleOpenMedia(BuildContext context, String filePath, String title, bool isVideo) {
    if (filePath.isEmpty) {
      CustomToast.showError(context, 'Path file tidak ditemukan.');
      return;
    }

    final file = File(filePath);
    final exists = file.existsSync();

    if (!exists) {
      CustomToast.showInfo(context, 'File fisik tersimpan langsung di Galeri / Folder Download HP Anda.');
      return;
    }

    if (isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoViewerPage(
            videoUrl: filePath,
            title: title,
          ),
        ),
      );
    } else {
      OpenFilex.open(filePath).then((result) {
        if (result.type != ResultType.done && mounted) {
          CustomToast.showInfo(context, 'Membuka media: $title');
        }
      });
    }
  }

  Future<void> _handleShare(String filePath, String title, bool isVideo, String url) async {
    final success = await MediaStorageService.shareMediaFile(
      filePath: filePath,
      title: title,
      mediaType: isVideo ? 'video' : 'audio',
      fallbackUrl: url,
    );
    if (!success && mounted) {
      CustomToast.showInfo(context, 'Membuka menu bagikan...');
    }
  }

  Map<String, dynamic> _getPlatformInfo(String url, String title, String author) {
    final lower = '$url $title $author'.toLowerCase();
    if (lower.contains('tiktok') || lower.contains('douyin')) {
      return {'name': 'TikTok', 'icon': Icons.music_video_rounded, 'color': const Color(0xFFFE2C55)};
    } else if (lower.contains('instagram')) {
      return {'name': 'Instagram', 'icon': Icons.camera_alt_rounded, 'color': const Color(0xFFE1306C)};
    } else if (lower.contains('facebook') || lower.contains('fb.')) {
      return {'name': 'Facebook', 'icon': Icons.facebook_rounded, 'color': const Color(0xFF1877F2)};
    } else if (lower.contains('twitter') || lower.contains('x.com')) {
      return {'name': 'Twitter / X', 'icon': Icons.alternate_email_rounded, 'color': Colors.white70};
    } else if (lower.contains('youtube') || lower.contains('youtu.be')) {
      return {'name': 'YouTube', 'icon': Icons.play_circle_fill_rounded, 'color': const Color(0xFFFF0000)};
    } else if (lower.contains('spotify')) {
      return {'name': 'Spotify', 'icon': Icons.headphones_rounded, 'color': const Color(0xFF1DB954)};
    } else if (lower.contains('soundcloud')) {
      return {'name': 'SoundCloud', 'icon': Icons.graphic_eq_rounded, 'color': const Color(0xFFFF5500)};
    } else if (lower.contains('apple')) {
      return {'name': 'Apple Music', 'icon': Icons.music_note_rounded, 'color': const Color(0xFFFA243C)};
    } else if (lower.contains('terabox')) {
      return {'name': 'TeraBox', 'icon': Icons.cloud_download_rounded, 'color': const Color(0xFF0086FF)};
    } else if (lower.contains('capcut')) {
      return {'name': 'CapCut', 'icon': Icons.content_cut_rounded, 'color': const Color(0xFF00E5FF)};
    } else if (lower.contains('threads')) {
      return {'name': 'Threads', 'icon': Icons.forum_rounded, 'color': Colors.white70};
    } else if (lower.contains('pinterest') || lower.contains('pin.it')) {
      return {'name': 'Pinterest', 'icon': Icons.push_pin_rounded, 'color': const Color(0xFFE60023)};
    }
    return {'name': 'Media', 'icon': Icons.download_done_rounded, 'color': AppColors.primary};
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final historyProvider = context.watch<HistoryProvider>();
    final items = historyProvider.filteredItems;
    final allItems = historyProvider.allItems;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    int totalBytes = 0;
    for (final item in allItems) {
      totalBytes += item.totalBytes;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Unduhan'),
        automaticallyImplyLeading: false,
        actions: [
          if (allItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.textMuted, size: 22),
              tooltip: 'Bersihkan Riwayat',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF18181B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 10),
                        Text('Bersihkan Riwayat?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: const Text(
                      'Semua daftar riwayat unduhan akan dibersihkan dari aplikasi. File di galeri HP Anda tetap aman.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          historyProvider.clearAll();
                          CustomToast.showSuccess(context, 'Riwayat berhasil dibersihkan');
                        },
                        child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          // 1. Summary Header Card (Only when items exist)
          if (allItems.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(isCompact ? 12 : 20, 8, isCompact ? 12 : 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(Icons.folder_special_rounded, '${allItems.length}', 'Total Media', const Color(0xFF38BDF8)),
                    Container(height: 28, width: 1, color: Colors.white10),
                    _buildStatItem(Icons.movie_filter_rounded, '${allItems.where((i) => i.isVideo).length}', 'Video MP4', const Color(0xFFA855F7)),
                    Container(height: 28, width: 1, color: Colors.white10),
                    _buildStatItem(Icons.library_music_rounded, '${allItems.where((i) => !i.isVideo && !i.isPhotos).length}', 'Audio MP3', const Color(0xFF22C55E)),
                    Container(height: 28, width: 1, color: Colors.white10),
                    _buildStatItem(Icons.pie_chart_outline_rounded, totalBytes > 0 ? Formatters.formatBytes(totalBytes) : 'Galeri', 'Kapasitas', const Color(0xFFF59E0B)),
                  ],
                ),
              ),
            ),

          // 2. Search Bar & Filter Chips
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 20, vertical: 4),
            child: Column(
              children: [
                // Search Input
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => historyProvider.setSearchQuery(value),
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Cari riwayat video, audio, atau author...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        icon: Icons.all_inclusive_rounded,
                        label: 'Semua (${allItems.length})',
                        isSelected: historyProvider.selectedFilter == HistoryFilter.all,
                        onTap: () => historyProvider.setFilter(HistoryFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        icon: Icons.videocam_rounded,
                        label: 'Video MP4 (${allItems.where((i) => i.isVideo).length})',
                        isSelected: historyProvider.selectedFilter == HistoryFilter.video,
                        onTap: () => historyProvider.setFilter(HistoryFilter.video),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        icon: Icons.audiotrack_rounded,
                        label: 'Audio MP3 (${allItems.where((i) => !i.isVideo && !i.isPhotos).length})',
                        isSelected: historyProvider.selectedFilter == HistoryFilter.audio,
                        onTap: () => historyProvider.setFilter(HistoryFilter.audio),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        icon: Icons.photo_library_rounded,
                        label: 'Slide Foto (${allItems.where((i) => i.isPhotos).length})',
                        isSelected: historyProvider.selectedFilter == HistoryFilter.photos,
                        onTap: () => historyProvider.setFilter(HistoryFilter.photos),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 3. History List Items
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: items.isEmpty
                  ? Center(
                      key: const ValueKey('history_empty'),
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
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'Tidak ada hasil untuk "${_searchController.text}"'
                                : 'Belum ada riwayat unduhan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'Coba kata kunci lain atau bersihkan filter pencarian'
                                : 'Semua media yang diunduh akan otomatis tercatat rapi di sini',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      key: const ValueKey('history_list'),
                      color: Colors.white,
                      backgroundColor: AppColors.surface,
                      onRefresh: () => historyProvider.syncWithStorage(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(isCompact ? 12 : 20, 6, isCompact ? 12 : 20, 100),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildHistoryCard(context, item);
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, DownloadItem item) {
    final fileExists = item.filePath.isNotEmpty && File(item.filePath).existsSync();
    final platformInfo = _getPlatformInfo(item.sourceUrl, item.title, item.author);
    final platformColor = platformInfo['color'] as Color;
    final platformName = platformInfo['name'] as String;
    final platformIcon = platformInfo['icon'] as IconData;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 18,
      onTap: () => _handleOpenMedia(context, item.filePath, item.title, item.isVideo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thumbnail Container with Overlay Badges
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 68,
                      height: 68,
                      color: const Color(0xFF1E1E24),
                      child: item.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              item.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFF1E1E24),
                                child: Icon(
                                  item.isPhotos
                                      ? Icons.photo_library_rounded
                                      : (item.isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded),
                                  color: AppColors.textMuted,
                                  size: 28,
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF1E1E24),
                              child: Icon(
                                item.isPhotos
                                    ? Icons.photo_library_rounded
                                    : (item.isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded),
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                            ),
                    ),
                  ),

                  // Center Play Icon / Music Icon
                  if (item.isVideo)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                    )
                  else if (!item.isPhotos)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: platformColor.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.audiotrack_rounded, color: Colors.white, size: 14),
                    ),

                  // Bottom Pill for Photos
                  if (item.isPhotos)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.mediaCount}P',
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // 2. Info Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Platform badge + File status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: platformColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: platformColor.withOpacity(0.3), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(platformIcon, color: platformColor, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                platformName,
                                style: TextStyle(color: platformColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (!fileExists && !item.isPhotos)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Galeri HP',
                              style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      item.title.isNotEmpty ? item.title : 'MyDownloader Media',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Author & Size
                    Text(
                      item.isPhotos
                          ? '${item.mediaCount} Foto Tersimpan • Galeri'
                          : '${item.author.isNotEmpty ? item.author : 'Creator'} • ${item.totalBytes > 0 ? Formatters.formatBytes(item.totalBytes) : 'Direct Media'}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Date
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppColors.textDisabled, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.formatDate(item.createdAt),
                          style: const TextStyle(color: AppColors.textDisabled, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: AppColors.textSecondary, size: 18),
                    tooltip: 'Bagikan',
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _handleShare(item.filePath, item.title, item.isVideo, item.sourceUrl),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
                    tooltip: 'Hapus',
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    padding: const EdgeInsets.all(6),
                    onPressed: () {
                      context.read<HistoryProvider>().deleteItem(item.id);
                      CustomToast.showSuccess(context, 'Dihapus dari riwayat');
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    IconData? icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13.5,
                color: isSelected ? Colors.black : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
