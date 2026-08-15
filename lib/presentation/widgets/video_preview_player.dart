import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../pages/video_viewer_page.dart';

class VideoPreviewPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final String title;
  final double aspectRatio;

  const VideoPreviewPlayer({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    this.aspectRatio = 9 / 16,
  });

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    if (widget.videoUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Referer': 'https://www.tiktok.com/',
        },
      );

      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.setVolume(1.0);

      _controller!.addListener(() {
        if (mounted) {
          final isPlaying = _controller?.value.isPlaying ?? false;
          if (_isPlaying != isPlaying) {
            setState(() => _isPlaying = isPlaying);
          }
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        // Auto play on preview
        _controller!.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    final newMute = !_isMuted;
    _controller!.setVolume(newMute ? 0.0 : 1.0);
    setState(() => _isMuted = newMute);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFF0D0D0E),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Thumbnail Background
              if (widget.thumbnailUrl.isNotEmpty)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: widget.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 40),
                    ),
                  ),
                ),

              // 2. Video Player Surface
              if (_isInitialized && _controller != null)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                ),

              // 3. Vignette Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // 4. Center Play / Pause indicator (when paused)
              if (_isInitialized && !_isPlaying)
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

              // 5. Loading Spinner
              if (!_isInitialized && !_hasError)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),

              // 6. Top Actions (Fullscreen & Mute)
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    if (_isInitialized)
                      _buildIconButton(
                        icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        onTap: _toggleMute,
                      ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: Icons.fullscreen_rounded,
                      onTap: () {
                        _controller?.pause();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoViewerPage(
                              videoUrl: widget.videoUrl,
                              title: widget.title,
                            ),
                          ),
                        ).then((_) {
                          if (mounted && _isInitialized) {
                            _controller?.play();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              // 7. Progress Bar at the bottom
              if (_isInitialized && _controller != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white.withOpacity(0.3),
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
