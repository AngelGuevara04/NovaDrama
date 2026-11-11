import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/drama_model.dart';
import '../models/episode_model.dart';

class DramaService {
  static final YoutubeExplode _yt = YoutubeExplode();

  /// Palabras clave de canales trampa (reacciones, críticas con pantalla dividida y marcas de agua)
  static final List<String> _spamKeywords = [
    'critica',
    'crítica',
    'reacion',
    'reaccion',
    'reacción',
    'reaction',
    'review',
    'datos y explicacion',
    'explicacion',
    'explicación',
    'trailer',
    'tráiler',
    'resumen',
    'lyric',
    'musica',
    'letra',
    'cancion',
  ];

  static bool _isSpamTitle(String title) {
    final lower = title.toLowerCase();
    return _spamKeywords.any((k) => lower.contains(k));
  }

  /// Genera capítulos virtuales a partir de una película / serie completa continua
  static List<EpisodeModel> createEpisodesFromFullVideo({
    required String videoId,
    required String dramaTitle,
    required int totalDurationSeconds,
    required String thumbnailUrl,
    int episodeCount = 45,
  }) {
    final episodes = <EpisodeModel>[];
    if (totalDurationSeconds <= 0) return episodes;

    final epDuration = (totalDurationSeconds / episodeCount).round();

    for (int i = 0; i < episodeCount; i++) {
      final start = i * epDuration;
      final end = (i == episodeCount - 1) ? totalDurationSeconds : (i + 1) * epDuration;
      episodes.add(
        EpisodeModel(
          id: '${videoId}_ep_${i + 1}',
          title: 'Capítulo ${i + 1}',
          episodeNumber: i + 1,
          videoUrl: videoId,
          thumbnailUrl: thumbnailUrl,
          duration: Duration(seconds: end - start),
          startSeconds: start,
          endSeconds: end,
          isYouTube: true,
        ),
      );
    }
    return episodes;
  }

  /// Dramas populares precargados con fuentes limpias verticales verificadas
  static List<DramaModel> getFeaturedDramas() {
    // 4Ng0WYUQtXA es el video oficial limpio en vertical de NetShort (2:36:52 = 9412 segundos)
    const poderAmantesVideoId = '4Ng0WYUQtXA';
    final poderAmantesEpisodes = createEpisodesFromFullVideo(
      videoId: poderAmantesVideoId,
      dramaTitle: 'El poder viene de mis amantes',
      totalDurationSeconds: 9412,
      thumbnailUrl: 'https://i.ytimg.com/vi/4Ng0WYUQtXA/maxresdefault.jpg',
      episodeCount: 45,
    );

    return [
      DramaModel(
        id: 'drama_poder_amantes',
        title: 'El poder viene de mis amantes',
        description:
            'Humillada por su propia familia en la selección de esposas, Claire despierta el místico Sistema de Apareamiento y Poder: cada unión romántica la hace más fuerte para reclamar su destino como Soberana Dragón.',
        coverUrl: 'https://i.ytimg.com/vi/4Ng0WYUQtXA/maxresdefault.jpg',
        author: 'NetShort Oficial',
        genres: ['Romance', 'Fantasía', 'Venganza', 'NetShort'],
        episodes: poderAmantesEpisodes,
      ),
      DramaModel(
        id: 'drama_ceo_oculto',
        title: 'El CEO multimillonario y su doble vida',
        description:
            'Nadie sabe que el humilde conserje del que todos se burlan es en realidad el heredero del imperio financiero más grande del país.',
        coverUrl:
            'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=600&auto=format&fit=crop&q=80',
        author: 'DramaBox',
        genres: ['CEO', 'Romance', 'Venganza'],
        episodes: [],
      ),
      DramaModel(
        id: 'drama_regreso_heredera',
        title: 'El renacer de la verdadera heredera',
        description:
            'Despojada de su herencia y dada por muerta, regresa 5 años después como la mujer más poderosa de la alta sociedad para destruir a quienes la traicionaron.',
        coverUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80',
        author: 'ShortMax',
        genres: ['Venganza', 'Drama', 'Alta Sociedad'],
        episodes: [],
      ),
      DramaModel(
        id: 'drama_esposo_dragon',
        title: 'Mi esposo es el señor de los dragones',
        description:
            'Forzada a casarse con el hombre más despiadado de la capital imperial, descubre que él guarda un secreto milenario que cambiará el destino del mundo.',
        coverUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
        author: 'ReelShort',
        genres: ['Fantasía', 'Romance', 'Magia'],
        episodes: [],
      ),
    ];
  }

  /// Busca dramas filtrando canales trampa y organizando capítulos reales
  static Future<List<DramaModel>> searchDramas(String query) async {
    final List<DramaModel> results = [];
    try {
      final sanitizedQuery = query.trim();
      if (sanitizedQuery.isEmpty) return results;

      // 1. Buscar playlists (series estructuradas)
      final playlistSearch = await _yt.search.searchContent(
        '$sanitizedQuery drama capitulo completo',
      );

      for (var item in playlistSearch) {
        if (item is SearchPlaylist) {
          if (_isSpamTitle(item.title)) continue;

          try {
            final playlist = await _yt.playlists.get(item.id);
            final videoList = await _yt.playlists.getVideos(item.id).take(60).toList();

            final cleanVideos = videoList.where((v) => !_isSpamTitle(v.title)).toList();

            if (cleanVideos.isNotEmpty) {
              final episodes = <EpisodeModel>[];
              int epNum = 1;
              for (var v in cleanVideos) {
                episodes.add(
                  EpisodeModel(
                    id: v.id.value,
                    title: v.title,
                    episodeNumber: epNum++,
                    videoUrl: v.id.value,
                    thumbnailUrl: v.thumbnails.highResUrl,
                    duration: v.duration ?? Duration.zero,
                    isYouTube: true,
                  ),
                );
              }

              results.add(
                DramaModel(
                  id: 'pl_${playlist.id.value}',
                  title: playlist.title,
                  description: playlist.description.isNotEmpty
                      ? playlist.description
                      : 'Serie con ${episodes.length} episodios completos.',
                  coverUrl: episodes.first.thumbnailUrl,
                  author: playlist.author,
                  playlistId: playlist.id.value,
                  genres: ['Drama Corto', 'Serie'],
                  episodes: episodes,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error procesando playlist ${item.id}: $e');
          }
        }
      }

      // 2. Buscar videos individuales filtrando los títulos trampa/reacciones
      final videoQueries = [
        '$sanitizedQuery netshort drama',
        '$sanitizedQuery minidrama completo español',
        '$sanitizedQuery drama corto capitulo',
      ];

      for (var vQuery in videoQueries) {
        if (results.length >= 8) break;

        final videoSearch = await _yt.search.search(vQuery);

        for (var v in videoSearch) {
          if (_isSpamTitle(v.title)) continue;
          if (results.any((r) => r.id == 'vid_${v.id.value}')) continue;

          final durationSec = v.duration?.inSeconds ?? 0;

          // Si el video dura más de 12 minutos, es un drama completo compilado
          if (durationSec > 720) {
            final epCount = (durationSec / 180).clamp(10, 60).round();
            final eps = createEpisodesFromFullVideo(
              videoId: v.id.value,
              dramaTitle: v.title,
              totalDurationSeconds: durationSec,
              thumbnailUrl: v.thumbnails.highResUrl,
              episodeCount: epCount,
            );

            results.add(
              DramaModel(
                id: 'vid_${v.id.value}',
                title: v.title,
                description: 'Drama completo en español con $epCount capítulos.',
                coverUrl: v.thumbnails.highResUrl,
                author: v.author,
                genres: ['Drama Completo', 'HD'],
                episodes: eps,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error buscando dramas: $e');
    }
    return results;
  }

  /// Carga episodios para dramas de catálogo si no los tienen
  static Future<DramaModel> loadEpisodesForDrama(DramaModel drama) async {
    if (drama.episodes.isNotEmpty) {
      return drama;
    }

    try {
      final search = await searchDramas(drama.title);
      if (search.isNotEmpty && search.first.episodes.isNotEmpty) {
        return drama.copyWith(
          episodes: search.first.episodes,
          coverUrl: search.first.coverUrl,
        );
      }
    } catch (e) {
      debugPrint('Error cargando episodios de ${drama.title}: $e');
    }

    return drama;
  }

  /// Extrae la URL de video directa (.mp4) de mayor calidad reproducible
  static Future<String?> extractStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Prioridad 1: Muxed streams (audio + video integrado)
      if (manifest.muxed.isNotEmpty) {
        final muxedStream = manifest.muxed.withHighestBitrate();
        return muxedStream.url.toString();
      }

      // Prioridad 2: Video stream
      if (manifest.videoOnly.isNotEmpty) {
        final videoStream = manifest.videoOnly.withHighestBitrate();
        return videoStream.url.toString();
      }
    } catch (e) {
      debugPrint('Error extrayendo stream de $videoId: $e');
    }
    return null;
  }

  static Duration _parseDuration(String durationStr) {
    try {
      final parts = durationStr.split(':').map(int.parse).toList();
      if (parts.length == 2) {
        return Duration(minutes: parts[0], seconds: parts[1]);
      } else if (parts.length == 3) {
        return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
      }
    } catch (_) {}
    return Duration.zero;
  }

  static void dispose() {
    _yt.close();
  }
}
