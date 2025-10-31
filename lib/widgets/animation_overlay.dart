import 'package:flutter/material.dart';
import 'dart:math';

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

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void addAnimation(String emoji) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    final random = Random();
    final startX = random.nextDouble();

    setState(() {
      _controllers.add(controller);
      _animations.add(animation);
      _positions.add(Offset(startX, 1.0));
      _emojis.add(emoji);
    });

    controller.forward().then((_) {
      setState(() {
        final index = _controllers.indexOf(controller);
        if (index != -1) {
          _controllers.removeAt(index);
          _animations.removeAt(index);
          _positions.removeAt(index);
          _emojis.removeAt(index);
        }
      });
      controller.dispose();
    });
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
                child: Opacity(
                  opacity: 1.0 - progress,
                  child: Transform.scale(
                    scale: 1.0 + progress * 0.5,
                    child: Text(
                      _emojis[index],
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
