import 'package:flutter/material.dart';
import '../models/player_models.dart';

class ReactionButtons extends StatelessWidget {
  final Function(String emoji) onReactionTap;

  const ReactionButtons({super.key, required this.onReactionTap});

  static final List<Reaction> reactions = [
    Reaction(emoji: '❤️', label: 'Love'),
    Reaction(emoji: '😂', label: 'Laugh'),
    Reaction(emoji: '😮', label: 'Wow'),
    Reaction(emoji: '😢', label: 'Sad'),
    Reaction(emoji: '😡', label: 'Angry'),
    Reaction(emoji: '👏', label: 'Clap'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((reaction) {
          return Expanded(
            child: InkWell(
              onTap: () => onReactionTap(reaction.emoji),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(reaction.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      reaction.label,
                      style: Theme.of(context).textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
