import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../providers/history_provider.dart';
import '../providers/tiktok_provider.dart';
import '../widgets/custom_toast.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import 'video_result_page.dart';
import 'video_viewer_page.dart';

class HomePage extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomePage({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final tiktokProvider = context.watch<TikTokProvider>();
    final historyProvider = context.watch<HistoryProvider>();
    final recentItems = historyProvider.items.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIKTOK DOWNLOADER',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Pro Edition',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (onNavigateTab != null)
                    GlassCard(
                      padding: const EdgeInsets.all(8),
                      borderRadius: 12,
                      onTap: () => onNavigateTab!(3), // Go to settings
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              // 2. Hero Section
              const Text(
                'Download Video TikTok',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Simpan video & audio favorit Anda tanpa watermark dengan kualitas jernih dan kecepatan tinggi.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // 3. Main Input Box & Action Button
              GlassCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassTextField(
                      controller: tiktokProvider.urlController,
                      hintText: 'Paste tautan video TikTok di sini...',
                      hasError: tiktokProvider.errorMessage != null,
                      errorText: tiktokProvider.errorMessage,
                      onPaste: () async {
                        final success = await tiktokProvider.pasteFromClipboard();
                        if (success && context.mounted) {
                          CustomToast.show(
                            context,
                            message: 'Tautan TikTok berhasil ditempel!',
                            type: ToastType.success,
                          );
                        } else if (context.mounted && tiktokProvider.errorMessage != null) {
                          CustomToast.show(
                            context,
                            message: tiktokProvider.errorMessage!,
                            type: ToastType.warning,
                          );
                        }
                      },
                      onClear: () => tiktokProvider.clearInput(),
                      onSubmitted: (_) => _handleFetch(context, tiktokProvider),
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      text: tiktokProvider.isLoading ? 'Mengambil Data Video...' : 'Download Sekarang',
                      icon: Icons.download_rounded,
                      isLoading: tiktokProvider.isLoading,
                      onPressed: () => _handleFetch(context, tiktokProvider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 4. Key Feature Cards
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Keunggulan Aplikasi',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _featureCard(
                      icon: Icons.hd_outlined,
                      title: 'Tanpa Watermark',
                      desc: 'Kualitas HD asli',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _featureCard(
                      icon: Icons.music_note_rounded,
                      title: 'Ekstrak MP3',
                      desc: 'Format audio jernih',
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _featureCard(
                      icon: Icons.bolt_rounded,
                      title: 'Super Cepat',
                      desc: 'Streaming download',
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 5. Recent Downloads Section (if any)
              if (recentItems.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Unduhan Terakhir',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (onNavigateTab != null)
                      TextButton(
                        onPressed: () => onNavigateTab!(2), // Go to history
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = recentItems[index];
                    return GlassCard(
                      padding: const EdgeInsets.all(12),
                      borderRadius: 14,
                      onTap: () {
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
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (item.isVideo ? AppColors.primary : AppColors.secondary).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.isVideo ? Icons.videocam_rounded : Icons.audiotrack_rounded,
                              color: item.isVideo ? AppColors.primary : AppColors.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatRelativeDate(item.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _handleFetch(BuildContext context, TikTokProvider provider) async {
    final success = await provider.fetchVideo();
    if (success && provider.currentVideo != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoResultPage(video: provider.currentVideo!),
        ),
      );
    } else if (context.mounted && provider.errorMessage != null) {
      CustomToast.show(
        context,
        message: provider.errorMessage!,
        type: ToastType.error,
      );
    }
  }
}
