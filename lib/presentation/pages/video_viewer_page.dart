import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../widgets/glass_card.dart';

class VideoViewerPage extends StatefulWidget {
  final String filePath;
  final String title;

  const VideoViewerPage({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
        });
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.play();
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
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _cycleSpeed() {
    if (!_isInitialized) return;
    final speeds = [1.0, 1.25, 1.5, 2.0, 0.5];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    setState(() {
      _playbackSpeed = speeds[nextIndex];
      _controller.setPlaybackSpeed(_playbackSpeed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video Area
            Center(
              child: _hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image_rounded, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'File video tidak ditemukan atau tidak dapat diputar.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kembali'),
                        ),
                      ],
                    )
                  : !_isInitialized
                      ? const Center(
                          child: SpinKitRing(color: AppColors.primary, size: 40, lineWidth: 3),
                        )
                      : GestureDetector(
                          onTap: () => setState(() => _showControls = !_showControls),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio > 0
                                ? _controller.value.aspectRatio
                                : 9 / 16,
                            child: VideoPlayer(_controller),
                          ),
                        ),
            ),

            // Top Bar Overlay
            if (_showControls)
              Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(8),
                      borderRadius: 12,
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(8),
                      borderRadius: 12,
                      onTap: () {
                        Share.shareXFiles(
                          [XFile(widget.filePath)],
                          text: widget.title,
                        );
                      },
                      child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),

            // Bottom Controls Overlay
            if (_showControls && _isInitialized)
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: 20,
                  backgroundColor: Colors.black.withOpacity(0.65),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Seeker
                      Row(
                        children: [
                          Text(
                            Formatters.formatDuration(_controller.value.position.inSeconds),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: AppColors.primary,
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
                          Text(
                            Formatters.formatDuration(_controller.value.duration.inSeconds),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 10s back
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 24),
                            onPressed: () {
                              final pos = _controller.value.position - const Duration(seconds: 10);
                              _controller.seekTo(pos < Duration.zero ? Duration.zero : pos);
                            },
                          ),

                          // Play / Pause
                          Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 30,
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                                });
                              },
                            ),
                          ),

                          // 10s forward
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 24),
                            onPressed: () {
                              final pos = _controller.value.position + const Duration(seconds: 10);
                              _controller.seekTo(pos);
                            },
                          ),

                          // Speed
                          TextButton(
                            onPressed: _cycleSpeed,
                            child: Text(
                              '${_playbackSpeed}x',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
