import 'package:flutter/material.dart';

// Mock models for episodes and seasons
class Episode {
  final int episodeNumber;
  final String title;
  final String thumbnail;
  final Duration duration;

  Episode({
    required this.episodeNumber,
    required this.title,
    required this.thumbnail,
    required this.duration,
  });
}

class Season {
  final int seasonNumber;
  final List<Episode> episodes;

  Season({required this.seasonNumber, required this.episodes});
}

class EpisodeSelector extends StatefulWidget {
  final List<Season> seasons;
  final int currentSeasonIndex;
  final int currentEpisodeIndex;
  final Function(int seasonIndex, int episodeIndex) onEpisodeSelected;

  const EpisodeSelector({
    super.key,
    required this.seasons,
    required this.currentSeasonIndex,
    required this.currentEpisodeIndex,
    required this.onEpisodeSelected,
  });

  @override
  State<EpisodeSelector> createState() => _EpisodeSelectorState();
}

class _EpisodeSelectorState extends State<EpisodeSelector> {
  late int _selectedSeasonIndex;

  @override
  void initState() {
    super.initState();
    _selectedSeasonIndex = widget.currentSeasonIndex;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    // If only one episode (movie), don't show the selector
    if (widget.seasons.length == 1 && widget.seasons[0].episodes.length == 1) {
      return const SizedBox.shrink();
    }

    final currentSeason = widget.seasons[_selectedSeasonIndex];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Season selector dropdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.video_library,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Episodes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.seasons.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: DropdownButton<int>(
                      value: _selectedSeasonIndex,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: widget.seasons.asMap().entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text('Season ${entry.value.seasonNumber}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSeasonIndex = value;
                          });
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Episodes list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentSeason.episodes.length,
              itemBuilder: (context, index) {
                final episode = currentSeason.episodes[index];
                final isCurrentEpisode =
                    _selectedSeasonIndex == widget.currentSeasonIndex &&
                    index == widget.currentEpisodeIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      widget.onEpisodeSelected(_selectedSeasonIndex, index);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrentEpisode
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentEpisode
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Episode number badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCurrentEpisode
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${episode.episodeNumber}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentEpisode
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Episode info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  episode.title,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontWeight: isCurrentEpisode
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDuration(episode.duration),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          // Play icon for current episode
                          if (isCurrentEpisode)
                            Icon(
                              Icons.play_circle_filled,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
