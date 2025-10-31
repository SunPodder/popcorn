import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerView extends StatelessWidget {
  final Player player;
  final VideoController videoController;
  final VoidCallback onTap;

  const VideoPlayerView({
    super.key,
    required this.player,
    required this.videoController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: _getAspectRatio(),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Video(controller: videoController, controls: NoVideoControls),
        ),
      ),
    );
  }

  double _getAspectRatio() {
    if (player.state.width != null && player.state.height != null) {
      return player.state.width! / player.state.height!;
    }
    return 16 / 9;
  }
}
