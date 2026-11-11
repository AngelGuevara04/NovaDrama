class EpisodeModel {
  final String id;
  final String title;
  final int episodeNumber;
  final String videoUrl; // Puede ser un videoId de YouTube o una URL directa MP4/M3U8
  final String? directStreamUrl;
  final String thumbnailUrl;
  final Duration duration;
  final bool isYouTube;

  EpisodeModel({
    required this.id,
    required this.title,
    required this.episodeNumber,
    required this.videoUrl,
    this.directStreamUrl,
    required this.thumbnailUrl,
    this.duration = Duration.zero,
    this.isYouTube = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'episodeNumber': episodeNumber,
        'videoUrl': videoUrl,
        'directStreamUrl': directStreamUrl,
        'thumbnailUrl': thumbnailUrl,
        'durationMs': duration.inMilliseconds,
        'isYouTube': isYouTube,
      };

  factory EpisodeModel.fromJson(Map<String, dynamic> json) => EpisodeModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Episodio',
        episodeNumber: (json['episodeNumber'] as num?)?.toInt() ?? 1,
        videoUrl: json['videoUrl'] as String? ?? '',
        directStreamUrl: json['directStreamUrl'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
        duration: Duration(milliseconds: (json['durationMs'] as num?)?.toInt() ?? 0),
        isYouTube: json['isYouTube'] as bool? ?? true,
      );

  EpisodeModel copyWith({
    String? directStreamUrl,
  }) {
    return EpisodeModel(
      id: id,
      title: title,
      episodeNumber: episodeNumber,
      videoUrl: videoUrl,
      directStreamUrl: directStreamUrl ?? this.directStreamUrl,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      isYouTube: isYouTube,
    );
  }
}
