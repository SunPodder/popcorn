import 'package:flutter/material.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String title;

  const VideoPlayerWidget({super.key, required this.title});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isPlaying = false;
  double _currentPosition = 0.3; // Mock progress (30%)
  bool _showControls = true;

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Mock video content
            Center(
              child: Icon(
                Icons.movie,
                size: 100,
                color: Colors.white.withOpacity(0.3),
              ),
            ),

            // Controls overlay
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.2, 0.7, 1.0],
                  ),
                ),
              ),

            // Top bar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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
              ),

            // Play/Pause button
            Center(
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 72,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),
            ),

            // Bottom controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      Row(
                        children: [
                          Text(
                            _formatDuration(Duration(minutes: 45)),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
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
                                  overlayRadius: 14,
                                ),
                              ),
                              child: Slider(
                                value: _currentPosition,
                                onChanged: (value) {
                                  setState(() {
                                    _currentPosition = value;
                                  });
                                },
                                activeColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                inactiveColor: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(Duration(hours: 2, minutes: 30)),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.replay_10,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.forward_10,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // Will be implemented with fullscreen functionality
                                },
                              ),
                            ],
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
}
