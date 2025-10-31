import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import '../generated/emoji_reactions.dart';

enum EmojiAnimationType {
  floatUp,
  bounce,
  explode,
  spin,
  pulse,
  // Add more animation types as needed
}

class EmojiAnimationConfig {
  final EmojiAnimationType type;
  final Duration duration;
  final Curve curve;

  const EmojiAnimationConfig({
    required this.type,
    this.duration = const Duration(milliseconds: 2000),
    this.curve = Curves.easeOut,
  });
}

class AnimationOverlay extends StatefulWidget {
  const AnimationOverlay({super.key});

  @override
  AnimationOverlayState createState() => AnimationOverlayState();
}

// Expose state class publicly
class AnimationOverlayState extends State<AnimationOverlay>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];
  final List<Offset> _positions = [];
  final List<String> _emojis = [];
  final List<EmojiAnimationConfig> _configs = [];

  // Map specific emojis to their custom animations
  // Add more custom mappings here as you implement specific animations
  static const Map<String, EmojiAnimationType> _emojiAnimationMap = {
    '❤': EmojiAnimationType.pulse,
    '😂': EmojiAnimationType.bounce,
    '💥': EmojiAnimationType.explode,
    '🌟': EmojiAnimationType.spin,
    // Add more emoji-specific animations here
  };

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  EmojiAnimationConfig _getAnimationConfig(String emoji) {
    // Check if this emoji has a custom animation
    final animationType = _emojiAnimationMap[emoji];

    if (animationType != null) {
      return EmojiAnimationConfig(type: animationType);
    }

    // Default animation for emojis without custom config
    return const EmojiAnimationConfig(type: EmojiAnimationType.floatUp);
  }

  void addAnimation(String emoji) {
    final config = _getAnimationConfig(emoji);

    final controller = AnimationController(
      duration: config.duration,
      vsync: this,
    );

    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: config.curve));

    final random = Random();
    final startX = random.nextDouble();

    setState(() {
      _controllers.add(controller);
      _animations.add(animation);
      _positions.add(Offset(startX, 1.0));
      _emojis.add(emoji);
      _configs.add(config);
    });

    controller.forward().then((_) {
      setState(() {
        final index = _controllers.indexOf(controller);
        if (index != -1) {
          _controllers.removeAt(index);
          _animations.removeAt(index);
          _positions.removeAt(index);
          _emojis.removeAt(index);
          _configs.removeAt(index);
        }
      });
      controller.dispose();
    });
  }

  String? _getEmojiAssetPath(String emoji) {
    // Find the matching emoji in the generated list
    try {
      final reaction = emojiReactions.firstWhere((r) => r.emoji == emoji);
      return reaction.assetPath;
    } catch (e) {
      return null;
    }
  }

  Widget _buildAnimatedEmoji(int index, double progress) {
    final config = _configs[index];
    final emoji = _emojis[index];
    final assetPath = _getEmojiAssetPath(emoji);

    Widget emojiWidget;
    if (assetPath != null) {
      emojiWidget = SvgPicture.asset(assetPath, width: 48, height: 48);
    } else {
      // Fallback to text emoji if SVG not found
      emojiWidget = Text(emoji, style: const TextStyle(fontSize: 48));
    }

    // Apply animation based on type
    switch (config.type) {
      case EmojiAnimationType.floatUp:
        return Opacity(
          opacity: 1.0 - progress,
          child: Transform.scale(
            scale: 1.0 + progress * 0.5,
            child: emojiWidget,
          ),
        );

      case EmojiAnimationType.bounce:
        // Bounce effect with sine wave
        final bounceOffset = sin(progress * pi * 4) * 20 * (1 - progress);
        return Transform.translate(
          offset: Offset(bounceOffset, 0),
          child: Opacity(
            opacity: 1.0 - progress,
            child: Transform.scale(
              scale: 1.0 + progress * 0.3,
              child: emojiWidget,
            ),
          ),
        );

      case EmojiAnimationType.explode:
        // Explode and fade out quickly
        return Opacity(
          opacity: 1.0 - (progress * 1.5).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1.0 + progress * 2.0,
            child: emojiWidget,
          ),
        );

      case EmojiAnimationType.spin:
        // Spin while floating up
        return Transform.rotate(
          angle: progress * pi * 4,
          child: Opacity(
            opacity: 1.0 - progress,
            child: Transform.scale(
              scale: 1.0 + progress * 0.5,
              child: emojiWidget,
            ),
          ),
        );

      case EmojiAnimationType.pulse:
        // Pulse effect with sine wave
        final pulseScale = 1.0 + sin(progress * pi * 6) * 0.2;
        return Opacity(
          opacity: 1.0 - progress,
          child: Transform.scale(scale: pulseScale, child: emojiWidget),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: List.generate(_animations.length, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final progress = _animations[index].value;
              final yPosition = _positions[index].dy - progress;

              return Positioned(
                left: _positions[index].dx * MediaQuery.of(context).size.width,
                bottom: yPosition * MediaQuery.of(context).size.height * 0.8,
                child: _buildAnimatedEmoji(index, progress),
              );
            },
          );
        }),
      ),
    );
  }
}
