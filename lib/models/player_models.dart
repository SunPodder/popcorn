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
