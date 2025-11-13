import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'video_player/video_player_view.dart';
import 'video_player/play_pause_indicator.dart';
import 'video_player/video_player_controls.dart';
import 'video_player/playback_speed_menu.dart';

/// Advanced video player with custom controls, playback speed, and fullscreen support
class AdvancedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final Function()? onFullscreenToggle;
  final bool isFullscreen;
  final Player? sharedPlayer;
  final VideoController? sharedVideoController;

  const AdvancedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    this.onFullscreenToggle,
    this.isFullscreen = false,
    this.sharedPlayer,
    this.sharedVideoController,
  });

  @override
  State<AdvancedVideoPlayer> createState() => _AdvancedVideoPlayerState();
}

class _AdvancedVideoPlayerState extends State<AdvancedVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeVideo();
  }

  void _initializeController() {
    _player = widget.sharedPlayer ?? Player();
    _videoController = widget.sharedVideoController ?? VideoController(_player);

    // Start with controls visible, then hide after initial delay
    _showControlsTemporarily();
  }

  void _initializeVideo() {
    // Only initialize if URL changed or first load
    if (_player.state.playlist.medias.isEmpty ||
        _player.state.playlist.medias.first.uri != widget.videoUrl) {
      _loadVideo();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _player.open(Media(widget.videoUrl));

      setState(() => _isLoading = false);

      // Auto-play
      _player.play();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load video: $e';
      });
    }
  }

  @override
  void didUpdateWidget(AdvancedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload if video URL changed
    if (oldWidget.videoUrl != widget.videoUrl) {
      _loadVideo();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    // Only dispose if we created the player (not shared)
    if (widget.sharedPlayer == null) {
      _player.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    _player.playOrPause();
    // Show controls temporarily when tapping video
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);

    // Auto-hide controls after 3 seconds
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _handleSpeedMenu() {
    PlaybackSpeedMenu.show(
      context,
      currentSpeed: _playbackSpeed,
      onSpeedChanged: (speed) {
        setState(() => _playbackSpeed = speed);
        _player.setRate(speed);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorView();
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    return _buildPlayer();
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadVideo, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading video...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return MouseRegion(
      onHover: (_) {
        // Show controls on mouse movement (both fullscreen and normal)
        _showControlsTemporarily();
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Video view with tap to play/pause
            VideoPlayerView(
              player: _player,
              videoController: _videoController,
              onTap: _togglePlayPause,
            ),

            // Play/pause indicator (only visible when paused)
            PlayPauseIndicator(player: _player),

            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: VideoPlayerControls(
                  player: _player,
                  title: widget.title,
                  onBack: () => Navigator.of(context).pop(),
                  onFullscreenToggle: widget.onFullscreenToggle,
                  onSpeedMenu: _handleSpeedMenu,
                  onPlayPause: _togglePlayPause,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
