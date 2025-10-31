import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/reaction_buttons.dart';
import '../widgets/live_chat_widget.dart';
import '../widgets/animation_overlay.dart';
import '../widgets/episode_selector.dart';

class PlayerScreen extends StatefulWidget {
  final Post post;

  const PlayerScreen({super.key, required this.post});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final GlobalKey<AnimationOverlayState> _animationKey = GlobalKey();
  bool _isFullscreen = false;
  bool _orientationInitialized = false;
  List<Season> _seasons = [];
  int _currentSeasonIndex = 0;
  int _currentEpisodeIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMockSeasons();
  }

  void _loadMockSeasons() {
    // Mock data - simulating a series with 2 seasons
    _seasons = [
      Season(
        seasonNumber: 1,
        episodes: [
          Episode(
            episodeNumber: 1,
            title: 'Pilot',
            thumbnail: '',
            duration: const Duration(minutes: 45),
          ),
          Episode(
            episodeNumber: 2,
            title: 'The Beginning',
            thumbnail: '',
            duration: const Duration(minutes: 42),
          ),
          Episode(
            episodeNumber: 3,
            title: 'Rising Tensions',
            thumbnail: '',
            duration: const Duration(minutes: 43),
          ),
          Episode(
            episodeNumber: 4,
            title: 'Revelations',
            thumbnail: '',
            duration: const Duration(minutes: 44),
          ),
        ],
      ),
      Season(
        seasonNumber: 2,
        episodes: [
          Episode(
            episodeNumber: 1,
            title: 'New Dawn',
            thumbnail: '',
            duration: const Duration(minutes: 46),
          ),
          Episode(
            episodeNumber: 2,
            title: 'Dark Secrets',
            thumbnail: '',
            duration: const Duration(minutes: 43),
          ),
          Episode(
            episodeNumber: 3,
            title: 'The Betrayal',
            thumbnail: '',
            duration: const Duration(minutes: 45),
          ),
        ],
      ),
    ];
  }

  void _onEpisodeSelected(int seasonIndex, int episodeIndex) {
    setState(() {
      _currentSeasonIndex = seasonIndex;
      _currentEpisodeIndex = episodeIndex;
    });
    // TODO: Load and play the selected episode
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
                  return VideoPlayerWidget(
                    title: widget.post.title ?? widget.post.name,
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
                            Expanded(
                              child: VideoPlayerWidget(
                                title: widget.post.title ?? widget.post.name,
                              ),
                            ),
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
                                labelColor:
                                    Theme.of(context).colorScheme.primary,
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
                      child: VideoPlayerWidget(
                        title: widget.post.title ?? widget.post.name,
                      ),
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
