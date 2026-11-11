import 'episode_model.dart';

class DramaModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String author;
  final List<String> genres;
  final List<EpisodeModel> episodes;
  final String? playlistId;
  final DateTime? lastWatchedAt;
  final int lastWatchedEpisodeIndex;
  final int lastWatchedPositionSeconds;

  DramaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.author,
    this.genres = const [],
    this.episodes = const [],
    this.playlistId,
    this.lastWatchedAt,
    this.lastWatchedEpisodeIndex = 0,
    this.lastWatchedPositionSeconds = 0,
  });

  int get totalEpisodes => episodes.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'coverUrl': coverUrl,
        'author': author,
        'genres': genres,
        'episodes': episodes.map((e) => e.toJson()).toList(),
        'playlistId': playlistId,
        'lastWatchedAt': lastWatchedAt?.toIso8601String(),
        'lastWatchedEpisodeIndex': lastWatchedEpisodeIndex,
        'lastWatchedPositionSeconds': lastWatchedPositionSeconds,
      };

  factory DramaModel.fromJson(Map<String, dynamic> json) => DramaModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        coverUrl: json['coverUrl'] as String? ?? '',
        author: json['author'] as String? ?? 'Desconocido',
        genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        episodes: (json['episodes'] as List<dynamic>?)
                ?.map((e) => EpisodeModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        playlistId: json['playlistId'] as String?,
        lastWatchedAt: json['lastWatchedAt'] != null
            ? DateTime.tryParse(json['lastWatchedAt'] as String)
            : null,
        lastWatchedEpisodeIndex: (json['lastWatchedEpisodeIndex'] as num?)?.toInt() ?? 0,
        lastWatchedPositionSeconds: (json['lastWatchedPositionSeconds'] as num?)?.toInt() ?? 0,
      );

  DramaModel copyWith({
    String? title,
    String? description,
    String? coverUrl,
    String? author,
    List<String>? genres,
    List<EpisodeModel>? episodes,
    String? playlistId,
    DateTime? lastWatchedAt,
    int? lastWatchedEpisodeIndex,
    int? lastWatchedPositionSeconds,
  }) {
    return DramaModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      author: author ?? this.author,
      genres: genres ?? this.genres,
      episodes: episodes ?? this.episodes,
      playlistId: playlistId ?? this.playlistId,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      lastWatchedEpisodeIndex: lastWatchedEpisodeIndex ?? this.lastWatchedEpisodeIndex,
      lastWatchedPositionSeconds: lastWatchedPositionSeconds ?? this.lastWatchedPositionSeconds,
    );
  }
}
