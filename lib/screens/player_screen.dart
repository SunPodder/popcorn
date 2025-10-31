import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/reaction_buttons.dart';
import '../widgets/live_chat_widget.dart';
import '../widgets/animation_overlay.dart';

class PlayerScreen extends StatefulWidget {
  final Post post;

  const PlayerScreen({super.key, required this.post});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final GlobalKey<AnimationOverlayState> _animationKey = GlobalKey();
  bool _isFullscreen = false;
  bool _orientationInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize orientation after context is available
    if (!_orientationInitialized) {
      _orientationInitialized = true;
      _setOrientation(false);
    }
  }

  @override
  void dispose() {
    // Reset orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _setOrientation(bool fullscreen) {
    if (fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Check if we're on mobile (screen width < 600)
      final isPortrait = MediaQuery.of(context).size.width < 600;
      if (isPortrait) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    _setOrientation(_isFullscreen);
  }

  void _handleReaction(String emoji) {
    // Trigger animation overlay
    final animationState = _animationKey.currentState;
    animationState?.addAnimation(emoji);

    // Show a brief snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent $emoji'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isTabletOrDesktop = size.width > 600;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: OrientationBuilder(
          builder: (context, orientation) {
            // Fullscreen mode - only show video player
            if (_isFullscreen) {
              return Stack(
                children: [
                  VideoPlayerWidget(
                    title: widget.post.title ?? widget.post.name,
                  ),
                  AnimationOverlay(key: _animationKey),
                ],
              );
            }

            // Desktop/Tablet Landscape Layout
            if (isTabletOrDesktop && isLandscape) {
              return Row(
                children: [
                  // Left side - Video player with reactions
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        // Video player
                        Expanded(
                          child: Stack(
                            children: [
                              VideoPlayerWidget(
                                title: widget.post.title ?? widget.post.name,
                              ),
                              AnimationOverlay(key: _animationKey),
                            ],
                          ),
                        ),
                        // Reaction buttons
                        ReactionButtons(onReactionTap: _handleReaction),
                      ],
                    ),
                  ),
                  // Right side - Chat
                  SizedBox(width: 400, child: LiveChatWidget()),
                ],
              );
            }

            // Mobile Portrait Layout
            return Column(
              children: [
                // Video player
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      VideoPlayerWidget(
                        title: widget.post.title ?? widget.post.name,
                      ),
                      AnimationOverlay(key: _animationKey),
                    ],
                  ),
                ),
                // Reaction buttons
                ReactionButtons(onReactionTap: _handleReaction),
                // Chat
                const Expanded(child: LiveChatWidget()),
              ],
            );
          },
        ),
      ),
    );
  }
}
