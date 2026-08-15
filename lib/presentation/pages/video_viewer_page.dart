import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../widgets/custom_toast.dart';

class VideoViewerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoViewerPage({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage> {
  VideoPlayerController? _controller;
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

      await _controller!.initialize().timeout(const Duration(seconds: 15));
      _controller!.addListener(() {
        if (mounted) setState(() {});
      });
      _controller!.play();

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
      } else {
        _controller!.play();
      }
    });
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_isInitialized) return;
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    _controller!.seekTo(target);
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _openInExternalPlayer() {
    if (!widget.videoUrl.startsWith('http')) {
      OpenFilex.open(widget.videoUrl).then((result) {
        if (result.type != ResultType.done && mounted) {
          CustomToast.showInfo(context, 'Membuka di pemutar video eksternal...');
        }
      });
    } else {
      CustomToast.showInfo(context, 'Unduh video terlebih dahulu untuk memutar di aplikasi luar.');
    }
  }

  void _shareMedia() {
    if (!widget.videoUrl.startsWith('http') && File(widget.videoUrl).existsSync()) {
      Share.shareXFiles([XFile(widget.videoUrl)], text: widget.title);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = !widget.videoUrl.startsWith('http');

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Center Video Player Surface or Fallback
            Center(
              child: _isInitialized && _controller != null && !_hasError
                  ? GestureDetector(
                      onTap: () => setState(() => _showControls = !_showControls),
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio > 0
                            ? _controller!.value.aspectRatio
                            : (9 / 16),
                        child: VideoPlayer(_controller!),
                      ),
                    )
                  : _hasError
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_circle_outline_rounded, color: Colors.white70, size: 54),
                              const SizedBox(height: 16),
                              const Text(
                                'Buka di Pemutar Eksternal',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Gunakan pemutar video bawaan HP (Google Photos, VLC, Galeri) untuk memutar media ini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 24),
                              if (isLocal)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  ),
                                  onPressed: _openInExternalPlayer,
                                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                                  label: const Text('Buka di Pemutar HP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _hasError = false;
                                    _isInitialized = false;
                                  });
                                  _initializePlayer();
                                },
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                                label: const Text('Coba Putar Lagi', style: TextStyle(color: Colors.white70)),
                              ),
                            ],
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
            ),

            // 2. Top Header Navigation
            if (_showControls || _hasError)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title.isNotEmpty ? widget.title : 'Video TikTok',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isLocal) ...[
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                          tooltip: 'Bagikan',
                          onPressed: _shareMedia,
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
                          tooltip: 'Buka di Pemutar HP',
                          onPressed: _openInExternalPlayer,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // 3. Center Play/Pause & Quick Seek
            if (_showControls && _isInitialized && _controller != null)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded, color: Colors.white70, size: 36),
                      onPressed: () => _seekRelative(-10),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded, color: Colors.white70, size: 36),
                      onPressed: () => _seekRelative(10),
                    ),
                  ],
                ),
              ),

            // 4. Bottom Controls & Progress
            if (_showControls && _isInitialized && _controller != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white12,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${Formatters.formatDuration(_controller!.value.position.inSeconds)} / ${Formatters.formatDuration(_controller!.value.duration.inSeconds)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          IconButton(
                            icon: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                color: Colors.white, size: 20),
                            onPressed: _toggleMute,
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
