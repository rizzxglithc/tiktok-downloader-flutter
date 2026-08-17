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

class VideoResultPage extends StatefulWidget {
  final TikTokVideo video;

  const VideoResultPage({super.key, required this.video});

  @override
  State<VideoResultPage> createState() => _VideoResultPageState();
}

class _VideoResultPageState extends State<VideoResultPage> {
  int _currentSlideIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final video = widget.video;
    final isSlide = video.isSlide && video.images.isNotEmpty;
    final isAudioOnly = video.contentType == MediaContentType.audio;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isSlide
              ? 'Detail Slide Foto'
              : (isAudioOnly ? 'Detail Musik & Audio' : 'Detail Media'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(isCompact ? 14 : 20, 8, isCompact ? 14 : 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Media Preview Area: Photo Slide Carousel, Audio Art, or Video Player
            if (isSlide)
              _buildPhotoCarousel(screenWidth)
            else if (isAudioOnly)
              _buildAudioCard(screenWidth)
            else
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: screenWidth > 500 ? 420 : 360,
                  ),
                  child: VideoPreviewPlayer(
                    videoUrl: video.bestVideoUrl,
                    thumbnailUrl: video.coverUrl,
                    title: video.title,
                  ),
                ),
              ),

            const SizedBox(height: 18),

            // 2. Author Profile & Metadata Card
            GlassCard(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    video.authorName.isNotEmpty ? video.authorName : video.authorUsername,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    video.platformDisplayName,
                                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              video.authorUsername,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSlide)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${video.images.length} Slide Foto',
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        )
                      else if (video.durationSeconds > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            Formatters.formatDuration(video.durationSeconds),
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),

                  // Auto-Detect Media & Audio Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildStatusPill(
                        icon: isSlide
                            ? Icons.photo_library_rounded
                            : (isAudioOnly
                                ? Icons.audiotrack_rounded
                                : (video.title.toLowerCase().contains('.zip') ||
                                        video.title.toLowerCase().contains('.rar') ||
                                        video.title.toLowerCase().contains('.pdf') ||
                                        video.title.toLowerCase().contains('.apk')
                                    ? Icons.insert_drive_file_rounded
                                    : Icons.videocam_rounded)),
                        label: isSlide
                            ? '${video.images.length} Slide Foto'
                            : (isAudioOnly
                                ? 'Lagu / Audio'
                                : (video.title.toLowerCase().contains('.zip') ||
                                        video.title.toLowerCase().contains('.rar') ||
                                        video.title.toLowerCase().contains('.pdf') ||
                                        video.title.toLowerCase().contains('.apk')
                                    ? 'File Dokumen / Arsip'
                                    : 'Video')),
                        color: Colors.white.withOpacity(0.08),
                        textColor: Colors.white,
                      ),
                      _buildStatusPill(
                        icon: video.hasAudio ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        label: video.hasAudio ? 'Sound Asli Terdeteksi' : 'Tanpa Audio (Muted)',
                        color: video.hasAudio
                            ? const Color(0xFF22C55E).withOpacity(0.12)
                            : const Color(0xFFF97316).withOpacity(0.12),
                        textColor: video.hasAudio ? const Color(0xFF4ADE80) : const Color(0xFFFB923C),
                      ),
                    ],
                  ),

                  if (video.title.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (video.likesCount > 0 || video.viewsCount > 0) ...[
                    const SizedBox(height: 14),
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
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 3. Download Options
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

            // Download Buttons for Slide Carousel
            if (isSlide) ...[
              GlassButton(
                text: 'Unduh Semua Foto (${video.images.length} Slide Full HD)',
                icon: Icons.photo_library_rounded,
                onPressed: () async {
                  final started = await downloadProvider.startPhotoSlidesDownload(
                    video: video,
                    context: context,
                  );
                  if (started && context.mounted) {
                    CustomToast.showSuccess(context, 'Mengunduh ${video.images.length} foto ke Galeri...');
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 10),
              if (video.hasAudio) ...[
                GlassButton(
                  text: 'Unduh Audio / Musik MP3',
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
                      CustomToast.showSuccess(context, 'Pengunduhan audio dimulai');
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 10),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volume_off_rounded, color: AppColors.textMuted, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Konten slide ini tidak menyertakan trek audio.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else if (isAudioOnly) ...[
              // Audio only download (Spotify, SoundCloud, Audio)
              GlassButton(
                text: 'Unduh Lagu MP3 (Kualitas Penuh)',
                icon: Icons.music_note_rounded,
                onPressed: () async {
                  final started = await downloadProvider.startDownload(
                    video: video,
                    isVideo: false,
                    isHd: false,
                    context: context,
                  );
                  if (started && context.mounted) {
                    CustomToast.showSuccess(context, 'Pengunduhan audio dimulai');
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 10),
            ] else ...[
              // Download Buttons for Video
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
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volume_off_rounded, color: AppColors.textMuted, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Video ini berstatus hening (tanpa suara latar).',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel(double screenWidth) {
    final images = widget.video.images;
    return Container(
      width: double.infinity,
      height: 360,
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _currentSlideIndex = index),
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 48),
                ),
              );
            },
          ),
          // Slide Badge Counter
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: Text(
                '${_currentSlideIndex + 1} / ${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Slide Indicator Dots
          if (images.length > 1)
            Positioned(
              bottom: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(images.length > 8 ? 8 : images.length, (index) {
                  final isSelected = (index == _currentSlideIndex) ||
                      (index == 7 && _currentSlideIndex >= 7);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSelected ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioCard(double screenWidth) {
    final hasCover = widget.video.coverUrl.isNotEmpty;
    final isSpotify = widget.video.platform == MediaPlatform.spotify;
    final isApple = widget.video.platform == MediaPlatform.applemusic;
    final isSoundCloud = widget.video.platform == MediaPlatform.soundcloud;
    final isTerabox = widget.video.platform == MediaPlatform.terabox;

    Color themeColor = isSpotify
        ? const Color(0xFF1DB954)
        : (isApple
            ? const Color(0xFFFA243C)
            : (isSoundCloud
                ? const Color(0xFFFF5500)
                : (isTerabox ? const Color(0xFF0086FF) : AppColors.primary)));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor.withOpacity(0.08),
            const Color(0xFF141416),
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        children: [
          // Album Art Cover Container
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.25),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: hasCover
                    ? CachedNetworkImage(
                        imageUrl: widget.video.coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surface,
                          child: Icon(Icons.music_note_rounded, color: themeColor, size: 64),
                        ),
                      )
                    : Container(
                        color: AppColors.surface,
                        child: Icon(Icons.music_note_rounded, color: themeColor, size: 64),
                      ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Icon(Icons.audiotrack_rounded, color: themeColor, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title & Artist
          Text(
            widget.video.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            widget.video.authorName.isNotEmpty ? widget.video.authorName : 'Audio Track',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),

          // Quality & Format Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeColor.withOpacity(0.3)),
                ),
                child: Text(
                  widget.video.platformDisplayName,
                  style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MP3 • 320kbps HQ',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              if (widget.video.durationSeconds > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    Formatters.formatDuration(widget.video.durationSeconds),
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ],
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

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: textColor, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
