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
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isLoading = false;

  Future<void> _startPlayback() async {
    if (widget.videoUrl.isEmpty) {
      _openFullScreen();
      return;
    }

    if (_controller != null && _isInitialized) {
      _togglePlayPause();
      return;
    }

    setState(() => _isLoading = true);

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

      await _controller!.initialize().timeout(const Duration(seconds: 10));
      _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _openFullScreen();
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
          // 1. Video Player Surface or Thumbnail Cover
          if (_isInitialized && _controller != null)
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
              onTap: _startPlayback,
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
                  // Subtle Vignette
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.65)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Play Button or Spinner
          if (_isLoading)
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
          else if (!_isPlaying)
            GestureDetector(
              onTap: _startPlayback,
              child: Container(
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: isCompact ? 30 : 38,
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
