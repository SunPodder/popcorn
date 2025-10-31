import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class VideoPlayerControls extends StatefulWidget {
  final Player player;
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onFullscreenToggle;
  final VoidCallback? onSpeedMenu;
  final VoidCallback? onPlayPause;

  const VideoPlayerControls({
    super.key,
    required this.player,
    required this.title,
    this.onBack,
    this.onFullscreenToggle,
    this.onSpeedMenu,
    this.onPlayPause,
  });

  @override
  State<VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<VideoPlayerControls> {
  bool _showVolumeSlider = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Bottom controls
          SafeArea(
            top: false,
            child: Column(
              children: [
                // Progress bar
                _buildProgressBar(context),
                // Control buttons
                _buildControlButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final progress = duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          final newPosition = Duration(
                            milliseconds: (value * duration.inMilliseconds)
                                .round(),
                          );
                          widget.player.seek(newPosition);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Seek backward 10s
          IconButton(
            icon: const Icon(Icons.replay_10, color: Colors.white),
            onPressed: () {
              final currentPosition = widget.player.state.position;
              final newPosition = currentPosition - const Duration(seconds: 10);
              widget.player.seek(
                newPosition < Duration.zero ? Duration.zero : newPosition,
              );
            },
          ),

          // Play/Pause button
          StreamBuilder<bool>(
            stream: widget.player.stream.playing,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? widget.player.state.playing;
              return IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: widget.onPlayPause,
              );
            },
          ),

          // Seek forward 10s
          IconButton(
            icon: const Icon(Icons.forward_10, color: Colors.white),
            onPressed: () {
              final currentPosition = widget.player.state.position;
              final duration = widget.player.state.duration;
              final newPosition = currentPosition + const Duration(seconds: 10);
              widget.player.seek(
                newPosition > duration ? duration : newPosition,
              );
            },
          ),

          const Spacer(),

          // Volume control with slider
          _buildVolumeControl(),

          // Playback speed
          IconButton(
            icon: const Icon(Icons.speed, color: Colors.white),
            onPressed: widget.onSpeedMenu,
          ),

          // Fullscreen toggle
          if (widget.onFullscreenToggle != null)
            IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              onPressed: widget.onFullscreenToggle,
            ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl() {
    return StreamBuilder<double>(
      stream: widget.player.stream.volume,
      builder: (context, snapshot) {
        final volume = (snapshot.data ?? 100) / 100;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Volume slider (expandable)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _showVolumeSlider ? 100 : 0,
              child: _showVolumeSlider
                  ? SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: volume.clamp(0.0, 1.0),
                        onChanged: (value) {
                          widget.player.setVolume(value * 100);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Colors.white.withOpacity(0.3),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Volume icon button
            IconButton(
              icon: Icon(
                volume > 0.5
                    ? Icons.volume_up
                    : volume > 0
                    ? Icons.volume_down
                    : Icons.volume_off,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showVolumeSlider = !_showVolumeSlider;
                });
              },
            ),
          ],
        );
      },
    );
  }
}
