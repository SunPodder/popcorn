import 'package:flutter/material.dart';
import '../models/player_models.dart';

class LiveChatWidget extends StatefulWidget {
  const LiveChatWidget({super.key});

  @override
  State<LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<LiveChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMockMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMockMessages() {
    // Mock chat messages
    final mockMessages = [
      ChatMessage(
        username: 'MovieFan23',
        message: 'This movie is amazing! 🍿',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        userColor: Colors.blue,
      ),
      ChatMessage(
        username: 'CinemaLover',
        message: 'Just joined! What did I miss?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        userColor: Colors.green,
      ),
      ChatMessage(
        username: 'ActionFan88',
        message: 'That scene was incredible!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        userColor: Colors.orange,
      ),
      ChatMessage(
        username: 'FilmCritic',
        message: 'The cinematography is on point 🎬',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        userColor: Colors.purple,
      ),
      ChatMessage(
        username: 'PopcornKing',
        message: 'Who else is watching with friends?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        userColor: Colors.red,
      ),
    ];

    setState(() {
      _messages.addAll(mockMessages);
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          username: 'You',
          message: _messageController.text,
          timestamp: DateTime.now(),
          userColor: Theme.of(context).colorScheme.primary,
        ),
      );
    });

    _messageController.clear();

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Chat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_messages.length + 42}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: message.userColor,
                        child: Text(
                          message.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Message content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  message.username,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: message.userColor,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(message.timestamp),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.message,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Message input
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
