import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/post.dart';
import '../models/post_detail.dart';
import '../models/player_models.dart';
import '../models/room.dart' as room_model;
import '../widgets/advanced_video_player.dart';
import '../widgets/live_chat_widget.dart';
import '../widgets/animation_overlay.dart';
import '../widgets/episode_selector.dart';
import '../widgets/room_join_widget.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/user_service.dart';
import '../core/constants/app_constants.dart';

class PlayerScreen extends StatefulWidget {
  final Post post;

  const PlayerScreen({super.key, required this.post});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final GlobalKey<AnimationOverlayState> _animationKey = GlobalKey();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final UserService _userService = UserService();
  bool _isFullscreen = false;
  bool _orientationInitialized = false;
  List<Season> _seasons = [];
  int _currentSeasonIndex = 0;
  int _currentEpisodeIndex = 0;
  PostDetail? _postDetail;
  bool _isLoading = true;
  String? _error;
  String? _currentVideoUrl;
  Player? _sharedPlayer;
  VideoController? _sharedVideoController;

  // Room state
  bool _isInRoom = false;
  String? _roomId;
  String? _username;
  List<ChatMessage> _chatMessages = [];
  List<room_model.RoomUser> _roomUsers = [];
  bool _isHost = false;
  Timer? _syncTimer;
  bool _isSyncing = false; // Prevent recursive sync

  @override
  void initState() {
    super.initState();
    _sharedPlayer = Player();
    _sharedVideoController = VideoController(_sharedPlayer!);
    _loadPostDetails();
    _setupSocketConnection();
  }

  void _setupSocketConnection() {
    // Connect to socket server
    _socketService.connect(AppConstants.socketUrl);

    // Listen for room events
    _socketService.onRoomCreated = (room) {
      setState(() {
        _isInRoom = true;
        _roomId = room.id;
        _roomUsers = room.users;
        _isHost = _socketService.isHost;
      });

      // Start periodic sync if host
      if (_isHost) {
        _startPeriodicSync();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Room created: ${room.id}')));
    };

    _socketService.onRoomData = (room) {
      if (room != null) {
        setState(() {
          _isInRoom = true;
          _roomId = room.id;
          _roomUsers = room.users;
          _isHost = _socketService.isHost;
        });

        // Start periodic sync if host
        if (_isHost && _syncTimer == null) {
          _startPeriodicSync();
        }
      }
    };

    _socketService.onUserJoined = (user, users) {
      setState(() {
        _roomUsers = users;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$user joined the room')));
    };

    _socketService.onChatMessage = (message) {
      setState(() {
        _chatMessages.add(
          ChatMessage(
            username: message.username,
            message: message.message,
            timestamp: message.timestamp,
            userColor: _getUserColor(message.username),
          ),
        );
      });
    };

    // Listen for playback sync events
    _socketService.onSyncPlayback = (currentTime, isPlaying, timestamp) {
      if (!_isHost && !_isSyncing) {
        _handleRemoteSync(currentTime, isPlaying, timestamp);
      }
    };

    // Listen for playback control events
    _socketService.onPlaybackControl = (action, currentTime, timestamp) {
      if (!_isHost && !_isSyncing) {
        _handleRemotePlaybackControl(action, currentTime, timestamp);
      }
    };
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isHost && _roomId != null && _sharedPlayer != null) {
        final position = _sharedPlayer!.state.position.inMilliseconds / 1000.0;
        final isPlaying = _sharedPlayer!.state.playing;
        _socketService.syncPlayback(
          roomId: _roomId!,
          currentTime: position,
          isPlaying: isPlaying,
        );
      }
    });
  }

  void _handleRemoteSync(double currentTime, bool isPlaying, int timestamp) {
    if (_sharedPlayer == null || _isSyncing) return;

    _isSyncing = true;

    // Calculate latency compensation
    final now = DateTime.now().millisecondsSinceEpoch;
    final latency = (now - timestamp) / 1000.0; // Convert to seconds

    // Seek to position + latency compensation
    final targetTime = currentTime + latency;
    _sharedPlayer!.seek(Duration(milliseconds: (targetTime * 1000).round()));

    if (isPlaying && !_sharedPlayer!.state.playing) {
      _sharedPlayer!.play();
    } else if (!isPlaying && _sharedPlayer!.state.playing) {
      _sharedPlayer!.pause();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      _isSyncing = false;
    });
  }

  void _handleRemotePlaybackControl(
    String action,
    double currentTime,
    int timestamp,
  ) {
    if (_sharedPlayer == null || _isSyncing) return;

    _isSyncing = true;

    final now = DateTime.now().millisecondsSinceEpoch;
    final latency = (now - timestamp) / 1000.0;
    final targetTime = currentTime + latency;

    switch (action) {
      case 'play':
        _sharedPlayer!.seek(
          Duration(milliseconds: (targetTime * 1000).round()),
        );
        _sharedPlayer!.play();
        break;
      case 'pause':
        _sharedPlayer!.pause();
        _sharedPlayer!.seek(
          Duration(milliseconds: (currentTime * 1000).round()),
        );
        break;
      case 'seek':
        _sharedPlayer!.seek(
          Duration(milliseconds: (currentTime * 1000).round()),
        );
        break;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      _isSyncing = false;
    });
  }

  Color _getUserColor(String username) {
    // Generate consistent color for each user
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final hash = username.hashCode;
    return colors[hash.abs() % colors.length];
  }

  void _handleCreateRoom() {
    final username = _userService.uniqueUsername;
    setState(() {
      _username = username;
    });
    _socketService.createRoom(
      user: username,
      currentVideoUrl: _currentVideoUrl,
      playlist: [],
    );
  }

  void _handleJoinRoom(String roomId) {
    final username = _userService.uniqueUsername;
    setState(() {
      _username = username;
      _roomId = roomId;
    });
    _socketService.joinRoom(roomId: roomId, user: username);
  }

  void _handleSendMessage(String message) {
    if (_roomId == null || _username == null) return;

    final chatMessage = room_model.ChatMessage(
      username: _username!,
      message: message,
      timestamp: DateTime.now(),
    );

    _socketService.sendMessage(roomId: _roomId!, message: chatMessage);

    // Add to local messages immediately
    setState(() {
      _chatMessages.add(
        ChatMessage(
          username: _username!,
          message: message,
          timestamp: DateTime.now(),
          userColor: Theme.of(context).colorScheme.primary,
        ),
      );
    });
  }

  Future<void> _loadPostDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final postDetail = await _apiService.getPostDetail(widget.post.id);

      setState(() {
        _postDetail = postDetail;
        _isLoading = false;
      });

      // Process content and load seasons/episodes
      _processContent();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load content: $e';
      });
    }
  }

  void _processContent() {
    if (_postDetail == null) return;

    if (_postDetail!.isMovie) {
      // Single movie stream
      _currentVideoUrl = _postDetail!.movieStreamUrl;
      _seasons = [];
    } else if (_postDetail!.isSeries) {
      // Series with seasons and episodes
      final seasonContents = _postDetail!.seasons;
      _seasons = seasonContents.map((seasonContent) {
        return Season(
          seasonNumber: seasonContent.seasonNumber,
          episodes: seasonContent.episodes.map((episodeContent) {
            return Episode(
              episodeNumber: episodeContent.episodeNumber,
              title: episodeContent.title,
              thumbnail: '',
              duration:
                  episodeContent.estimatedDuration ??
                  const Duration(minutes: 45),
            );
          }).toList(),
        );
      }).toList();

      // Load first episode URL
      if (seasonContents.isNotEmpty && seasonContents[0].episodes.isNotEmpty) {
        _currentVideoUrl = seasonContents[0].episodes[0].link;
      }
    }

    setState(() {});
  }

  void _onEpisodeSelected(int seasonIndex, int episodeIndex) {
    if (_postDetail == null || !_postDetail!.isSeries) return;

    final seasonContents = _postDetail!.seasons;
    if (seasonIndex < seasonContents.length &&
        episodeIndex < seasonContents[seasonIndex].episodes.length) {
      setState(() {
        _currentSeasonIndex = seasonIndex;
        _currentEpisodeIndex = episodeIndex;
        _currentVideoUrl =
            seasonContents[seasonIndex].episodes[episodeIndex].link;
      });
    }
  }

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
    _syncTimer?.cancel();
    _sharedPlayer?.dispose();
    _socketService.disconnect();
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
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPostDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentVideoUrl == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'No video available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return AdvancedVideoPlayer(
      key: ValueKey(_currentVideoUrl),
      videoUrl: _currentVideoUrl!,
      title: widget.post.title ?? widget.post.name,
      onFullscreenToggle: _toggleFullscreen,
      isFullscreen: false,
      sharedPlayer: _sharedPlayer,
      sharedVideoController: _sharedVideoController,
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
        child: Stack(
          children: [
            OrientationBuilder(
              builder: (context, orientation) {
                // Fullscreen mode - only show video player
                if (_isFullscreen) {
                  if (_isLoading) {
                    return Container(
                      color: Colors.black,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (_error != null || _currentVideoUrl == null) {
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: Text(
                          _error ?? 'No video URL available',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  return AdvancedVideoPlayer(
                    key: ValueKey(_currentVideoUrl),
                    videoUrl: _currentVideoUrl!,
                    title: widget.post.title ?? widget.post.name,
                    onFullscreenToggle: _toggleFullscreen,
                    isFullscreen: true,
                    sharedPlayer: _sharedPlayer,
                    sharedVideoController: _sharedVideoController,
                  );
                }

                // Desktop/Tablet Landscape Layout
                if (isTabletOrDesktop && isLandscape) {
                  return Row(
                    children: [
                      // Left side - Video player only
                      Expanded(flex: 7, child: _buildVideoPlayer()),
                      // Right side - Chat and Episodes in tabs
                      SizedBox(
                        width: 400,
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                indicatorColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                labelColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                unselectedLabelColor: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                                tabs: const [
                                  Tab(
                                    icon: Icon(Icons.chat_bubble_outline),
                                    text: 'Chat',
                                  ),
                                  Tab(
                                    icon: Icon(Icons.video_library),
                                    text: 'Episodes',
                                  ),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _isInRoom
                                        ? LiveChatWidget(
                                            onReactionTap: _handleReaction,
                                            messages: _chatMessages,
                                            username: _username ?? '',
                                            roomId: _roomId ?? '',
                                            onSendMessage: _handleSendMessage,
                                            userCount: _roomUsers.length,
                                          )
                                        : RoomJoinWidget(
                                            onJoinRoom: _handleJoinRoom,
                                            onCreateRoom: _handleCreateRoom,
                                          ),
                                    EpisodeSelector(
                                      seasons: _seasons,
                                      currentSeasonIndex: _currentSeasonIndex,
                                      currentEpisodeIndex: _currentEpisodeIndex,
                                      onEpisodeSelected: _onEpisodeSelected,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Mobile Portrait Layout
                return Column(
                  children: [
                    // Video player
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildVideoPlayer(),
                    ),
                    // Chat and Episodes in tabs
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            TabBar(
                              indicatorColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              labelColor: Theme.of(context).colorScheme.primary,
                              unselectedLabelColor: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              tabs: const [
                                Tab(
                                  icon: Icon(Icons.chat_bubble_outline),
                                  text: 'Chat',
                                ),
                                Tab(
                                  icon: Icon(Icons.video_library),
                                  text: 'Episodes',
                                ),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _isInRoom
                                      ? LiveChatWidget(
                                          onReactionTap: _handleReaction,
                                          messages: _chatMessages,
                                          username: _username ?? '',
                                          roomId: _roomId ?? '',
                                          onSendMessage: _handleSendMessage,
                                          userCount: _roomUsers.length,
                                        )
                                      : RoomJoinWidget(
                                          onJoinRoom: _handleJoinRoom,
                                          onCreateRoom: _handleCreateRoom,
                                        ),
                                  EpisodeSelector(
                                    seasons: _seasons,
                                    currentSeasonIndex: _currentSeasonIndex,
                                    currentEpisodeIndex: _currentEpisodeIndex,
                                    onEpisodeSelected: _onEpisodeSelected,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Animation overlay on top of everything
            IgnorePointer(child: AnimationOverlay(key: _animationKey)),
          ],
        ),
      ),
    );
  }
}
