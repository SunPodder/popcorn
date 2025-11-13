import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/room.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  Room? _currentRoom;

  Room? get currentRoom => _currentRoom;
  bool get isConnected => _socket?.connected ?? false;
  bool get isHost => _currentRoom?.host?.username == _getCurrentUsername();

  String? _currentUsername;
  String? _getCurrentUsername() => _currentUsername;

  // Callbacks
  Function(Room room)? onRoomCreated;
  Function(Room? room)? onRoomData;
  Function(String user, List<RoomUser> users)? onUserJoined;
  Function(ChatMessage message)? onChatMessage;
  Function(double currentTime, bool isPlaying, int timestamp)? onSyncPlayback;
  Function(String action, double currentTime, int timestamp)? onPlaybackControl;

  void connect(String serverUrl) {
    if (_socket?.connected ?? false) return;

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/ws')
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket!.onError((error) {
      print('Socket error: $error');
    });

    // Listen for room events
    _socket!.on('room-created', (data) {
      final room = Room.fromJson(data['room']);
      _currentRoom = room;
      onRoomCreated?.call(room);
    });

    _socket!.on('room-data', (data) {
      if (data != null) {
        final room = Room.fromJson(data);
        _currentRoom = room;
        onRoomData?.call(room);
      } else {
        onRoomData?.call(null);
      }
    });

    _socket!.on('user-joined', (data) {
      final user = data['user'] as String;
      final users = (data['users'] as List<dynamic>)
          .map((u) => RoomUser.fromJson(u as Map<String, dynamic>))
          .toList();
      if (_currentRoom != null) {
        _currentRoom = Room(
          id: _currentRoom!.id,
          users: users,
          currentVideoUrl: _currentRoom!.currentVideoUrl,
          playlist: _currentRoom!.playlist,
          currentTime: _currentRoom!.currentTime,
          isPlaying: _currentRoom!.isPlaying,
        );
      }
      onUserJoined?.call(user, users);
    });

    _socket!.on('chat-message', (data) {
      final message = ChatMessage.fromJson(data);
      onChatMessage?.call(message);
    });

    // Listen for playback sync events
    _socket!.on('sync-playback', (data) {
      final currentTime = (data['currentTime'] as num).toDouble();
      final isPlaying = data['isPlaying'] as bool;
      final timestamp = data['timestamp'] as int;
      onSyncPlayback?.call(currentTime, isPlaying, timestamp);
    });

    // Listen for playback control events
    _socket!.on('playback-control', (data) {
      final action = data['action'] as String;
      final currentTime = (data['currentTime'] as num).toDouble();
      final timestamp = data['timestamp'] as int;
      onPlaybackControl?.call(action, currentTime, timestamp);
    });
  }

  void createRoom({
    required String user,
    String? currentVideoUrl,
    List<PlaylistItem>? playlist,
  }) {
    if (_socket?.connected != true) {
      print('Socket not connected');
      return;
    }

    _currentUsername = user;
    _socket!.emit('create-room', {
      'user': user,
      'current_video_url': currentVideoUrl ?? '',
      'playlist': playlist?.map((item) => item.toJson()).toList() ?? [],
    });
  }

  void joinRoom({required String roomId, required String user}) {
    if (_socket?.connected != true) {
      print('Socket not connected');
      return;
    }

    _currentUsername = user;
    _socket!.emit('join-room', {'roomId': roomId, 'user': user});
  }

  void syncPlayback({
    required String roomId,
    required double currentTime,
    required bool isPlaying,
  }) {
    if (_socket?.connected != true) {
      print('Socket not connected');
      return;
    }

    _socket!.emit('sync-playback', {
      'roomId': roomId,
      'currentTime': currentTime,
      'isPlaying': isPlaying,
    });
  }

  void sendPlaybackControl({
    required String roomId,
    required String action,
    required double currentTime,
  }) {
    if (_socket?.connected != true) {
      print('Socket not connected');
      return;
    }

    _socket!.emit('playback-control', {
      'roomId': roomId,
      'action': action,
      'currentTime': currentTime,
    });
  }

  void sendMessage({required String roomId, required ChatMessage message}) {
    if (_socket?.connected != true) {
      print('Socket not connected');
      return;
    }

    _socket!.emit('chat-message', {
      'roomId': roomId,
      'message': message.toJson(),
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentRoom = null;
  }
}
