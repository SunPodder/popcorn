import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/post.dart';
import '../models/post_detail.dart';
import '../widgets/advanced_video_player.dart';
import '../widgets/reaction_buttons.dart';
import '../widgets/live_chat_widget.dart';
import '../widgets/animation_overlay.dart';
import '../widgets/episode_selector.dart';
import '../services/api_service.dart';

class PlayerScreen extends StatefulWidget {
  final Post post;

  const PlayerScreen({super.key, required this.post});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final GlobalKey<AnimationOverlayState> _animationKey = GlobalKey();
  final ApiService _apiService = ApiService();
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

  @override
  void initState() {
    super.initState();
    _sharedPlayer = Player();
    _sharedVideoController = VideoController(_sharedPlayer!);
    _loadPostDetails();
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
    _sharedPlayer?.dispose();
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
                      // Left side - Video player with reactions
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            // Video player
                            Expanded(child: _buildVideoPlayer()),
                            // Reaction buttons
                            ReactionButtons(onReactionTap: _handleReaction),
                          ],
                        ),
                      ),
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
                                    const LiveChatWidget(),
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
                    // Reaction buttons
                    ReactionButtons(onReactionTap: _handleReaction),
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
                                  const LiveChatWidget(),
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
