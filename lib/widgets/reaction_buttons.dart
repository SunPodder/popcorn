import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../generated/emoji_reactions.dart';

class ReactionButtons extends StatelessWidget {
  final Function(String emoji) onReactionTap;

  const ReactionButtons({super.key, required this.onReactionTap});

  // Pinned reactions that are always visible
  static final List<int> pinnedIndices = [
    emojiReactions.indexWhere((r) => r.emoji == '❤'),
    emojiReactions.indexWhere((r) => r.emoji == '😂'),
    emojiReactions.indexWhere((r) => r.emoji == '😮'),
    emojiReactions.indexWhere((r) => r.emoji == '😢'),
    emojiReactions.indexWhere((r) => r.emoji == '😡'),
    emojiReactions.indexWhere((r) => r.emoji == '�'),
  ];

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Text(
              'Choose Reaction',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Emoji grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: emojiReactions.length,
                itemBuilder: (context, index) {
                  final reaction = emojiReactions[index];
                  return InkWell(
                    onTap: () {
                      onReactionTap(reaction.emoji);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgPicture.asset(
                        reaction.assetPath,
                        width: 32,
                        height: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinnedReactions = pinnedIndices
        .where((index) => index >= 0)
        .map((index) => emojiReactions[index])
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
        children: [
          // Pinned reaction buttons
          ...pinnedReactions.map((reaction) {
            return Expanded(
              child: InkWell(
                onTap: () => onReactionTap(reaction.emoji),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    reaction.assetPath,
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            );
          }),
          // More button to show emoji picker
          Expanded(
            child: InkWell(
              onTap: () => _showEmojiPicker(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
