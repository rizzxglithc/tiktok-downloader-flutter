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
                            '${video.images.length} Foto',
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
                text: 'Unduh Semua Foto (${video.images.length} Foto Full HD)',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.video.coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.video.coverUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.music_note_rounded, color: Colors.white, size: 60),
                  )
                : const Icon(Icons.music_note_rounded, color: Colors.white, size: 60),
          ),
          const SizedBox(height: 16),
          Text(
            widget.video.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.video.authorName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
}
