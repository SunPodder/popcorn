import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class PlayPauseIndicator extends StatelessWidget {
  final Player player;

  const PlayPauseIndicator({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      builder: (context, snapshot) {
        // Check actual state first, then stream data
        final isPlaying = snapshot.hasData
            ? snapshot.data!
            : player.state.playing;

        if (isPlaying) return const SizedBox.shrink();

        return Center(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        );
      },
    );
  }
}
