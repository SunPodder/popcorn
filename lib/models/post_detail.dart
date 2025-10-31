class PostDetail {
  final int id;
  final String? title;
  final String type;
  final String? image;
  final String? imageSm;
  final String? cover;
  final String? metaData;
  final String? tags;
  final dynamic content; // Can be String or List<SeasonContent>
  final int? view;
  final String name;
  final String? quality;
  final String? watchTime;
  final String? year;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostDetail({
    required this.id,
    this.title,
    required this.type,
    this.image,
    this.imageSm,
    this.cover,
    this.metaData,
    this.tags,
    required this.content,
    this.view,
    required this.name,
    this.quality,
    this.watchTime,
    this.year,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isMovie => content is String;
  bool get isSeries => content is List;

  String? get movieStreamUrl => isMovie ? content as String? : null;

  List<SeasonContent> get seasons {
    if (isSeries && content is List) {
      return (content as List)
          .map((season) => SeasonContent.fromJson(season))
          .toList();
    }
    return [];
  }

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    return PostDetail(
      id: json['id'] as int,
      title: json['title'] as String?,
      type: json['type'] as String? ?? 'movie',
      image: json['image'] as String?,
      imageSm: json['imageSm'] as String?,
      cover: json['cover'] as String?,
      metaData: json['metaData'] as String?,
      tags: json['tags'] as String?,
      content: json['content'],
      view: json['view'] as int?,
      name: json['name'] as String? ?? '',
      quality: json['quality'] as String?,
      watchTime: json['watchTime'] as String?,
      year: json['year'] as String?,
      userId: json['userId'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class SeasonContent {
  final String seasonName;
  final List<EpisodeContent> episodes;

  SeasonContent({required this.seasonName, required this.episodes});

  int get seasonNumber {
    final match = RegExp(r'(\d+)').firstMatch(seasonName);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  factory SeasonContent.fromJson(Map<String, dynamic> json) {
    return SeasonContent(
      seasonName: json['seasonName'] as String? ?? 'Season 1',
      episodes:
          (json['episodes'] as List?)
              ?.map((e) => EpisodeContent.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EpisodeContent {
  final String link;
  final String title;

  EpisodeContent({required this.link, required this.title});

  int get episodeNumber {
    final match = RegExp(r'E(\d+)', caseSensitive: false).firstMatch(title);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  Duration? get estimatedDuration {
    // Default duration, can be customized based on patterns
    return const Duration(minutes: 45);
  }

  factory EpisodeContent.fromJson(Map<String, dynamic> json) {
    return EpisodeContent(
      link: json['link'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }
}
