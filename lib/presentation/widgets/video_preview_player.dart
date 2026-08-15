import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';

class VideoPreviewPlayer extends StatefulWidget {
  final String videoUrl;
  final String? coverUrl;
  final VoidCallback? onFullscreen;

  const VideoPreviewPlayer({
    super.key,
    required this.videoUrl,
    this.coverUrl,
    this.onFullscreen,
  });

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.addListener(() {
        if (mounted) setState(() {});
      });
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    if (!_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Tidak dapat memutar preview video.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _initializePlayer();
                },
                child: const Text('Coba Lagi', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinKitRing(color: AppColors.primary, size: 36, lineWidth: 3),
              SizedBox(height: 14),
              Text(
                'Memuat preview video...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final duration = _controller.value.duration.inSeconds;
    final position = _controller.value.position.inSeconds;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Container(
          height: 320,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Surface
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio > 0
                      ? _controller.value.aspectRatio
                      : (9 / 16),
                  child: VideoPlayer(_controller),
                ),
              ),

              // Controls Overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Bar (Mute & Fullscreen)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _glassIconButton(
                              icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              onTap: _toggleMute,
                            ),
                            if (widget.onFullscreen != null) ...[
                              const SizedBox(width: 8),
                              _glassIconButton(
                                icon: Icons.fullscreen_rounded,
                                onTap: widget.onFullscreen!,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Center Play/Pause Button
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Progress & Timestamp
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              Formatters.formatDuration(position),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.5,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: Colors.white.withOpacity(0.25),
                                  thumbColor: AppColors.primary,
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                ),
                                child: Slider(
                                  value: _controller.value.position.inMilliseconds
                                      .toDouble()
                                      .clamp(0.0, _controller.value.duration.inMilliseconds.toDouble()),
                                  min: 0.0,
                                  max: _controller.value.duration.inMilliseconds > 0
                                      ? _controller.value.duration.inMilliseconds.toDouble()
                                      : 1.0,
                                  onChanged: (value) {
                                    _controller.seekTo(Duration(milliseconds: value.toInt()));
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Formatters.formatDuration(duration),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
