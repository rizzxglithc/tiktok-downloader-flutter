import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../pages/video_viewer_page.dart';

class VideoPreviewPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final String title;

  const VideoPreviewPlayer({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
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
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.videoUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      if (widget.videoUrl.startsWith('http://') || widget.videoUrl.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          httpHeaders: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Referer': 'https://www.tiktok.com/',
          },
        );
      } else {
        _controller = VideoPlayerController.file(File(widget.videoUrl));
      }

      await _controller!.initialize().timeout(const Duration(seconds: 12));
      _controller!.setLooping(true);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (_) {
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
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _openFullScreen() {
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _isPlaying = false);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoViewerPage(
          videoUrl: widget.videoUrl,
          title: widget.title,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 380, minHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Video Player Surface or Thumbnail
          if (_isInitialized && _controller != null && !_hasError)
            GestureDetector(
              onTap: _togglePlayPause,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio > 0
                      ? _controller!.value.aspectRatio
                      : (9 / 16),
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _openFullScreen,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.thumbnailUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: const Color(0xFF1C1C1E)),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF1C1C1E),
                        child: const Icon(Icons.movie_creation_outlined, color: AppColors.textMuted, size: 40),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF1C1C1E),
                      child: const Icon(Icons.movie_creation_outlined, color: AppColors.textMuted, size: 40),
                    ),
                  // Dark Vignette
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Play / Pause Overlay Icon
          if (!_isPlaying)
            GestureDetector(
              onTap: _isInitialized ? _togglePlayPause : _openFullScreen,
              child: Container(
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Icon(
                  _isInitialized ? Icons.play_arrow_rounded : Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: isCompact ? 28 : 36,
                ),
              ),
            ),

          // 3. Floating Controls (Mute & Fullscreen)
          Positioned(
            bottom: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isInitialized) ...[
                  _buildCircleButton(
                    icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    onTap: _toggleMute,
                  ),
                  const SizedBox(width: 8),
                ],
                _buildCircleButton(
                  icon: Icons.fullscreen_rounded,
                  onTap: _openFullScreen,
                ),
              ],
            ),
          ),

          // 4. Fallback badge
          if (_hasError)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Ketuk untuk Buka Player',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
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
