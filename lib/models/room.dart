class RoomUser {
  final String username;
  final String role; // 'host' or 'viewer'

  RoomUser({required this.username, required this.role});

  bool get isHost => role == 'host';

  factory RoomUser.fromJson(Map<String, dynamic> json) {
    return RoomUser(
      username: json['username'] as String,
      role: json['role'] as String? ?? 'viewer',
    );
  }

  Map<String, dynamic> toJson() {
    return {'username': username, 'role': role};
  }
}

class Room {
  final String id;
  final List<RoomUser> users;
  final String currentVideoUrl;
  final List<PlaylistItem> playlist;
  final double? currentTime; // Current playback time in seconds
  final bool? isPlaying; // Current playback state

  Room({
    required this.id,
    required this.users,
    required this.currentVideoUrl,
    required this.playlist,
    this.currentTime,
    this.isPlaying,
  });

  RoomUser? get host => users.firstWhere(
    (user) => user.isHost,
    orElse: () =>
        users.isNotEmpty ? users.first : RoomUser(username: '', role: 'host'),
  );

  List<String> get usernames => users.map((u) => u.username).toList();

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      users: (json['users'] as List<dynamic>)
          .map((user) => RoomUser.fromJson(user as Map<String, dynamic>))
          .toList(),
      currentVideoUrl: json['current_video_url'] as String? ?? '',
      playlist:
          (json['playlist'] as List<dynamic>?)
              ?.map(
                (item) => PlaylistItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      currentTime: (json['current_time'] as num?)?.toDouble(),
      isPlaying: json['is_playing'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'users': users.map((user) => user.toJson()).toList(),
      'current_video_url': currentVideoUrl,
      'playlist': playlist.map((item) => item.toJson()).toList(),
      'current_time': currentTime,
      'is_playing': isPlaying,
    };
  }
}

class PlaylistItem {
  final String title;
  final String url;

  PlaylistItem({required this.title, required this.url});

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'url': url};
  }
}

class ChatMessage {
  final String username;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.username,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      username: json['username'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
