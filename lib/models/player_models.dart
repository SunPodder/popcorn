import 'package:flutter/material.dart';

class ChatMessage {
  final String username;
  final String message;
  final DateTime timestamp;
  final Color? userColor;

  ChatMessage({
    required this.username,
    required this.message,
    required this.timestamp,
    this.userColor,
  });
}

class Reaction {
  final String emoji;
  final String label;

  Reaction({required this.emoji, required this.label});
}
