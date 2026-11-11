import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/drama_model.dart';
import '../models/episode_model.dart';

class DramaService {
  static final YoutubeExplode _yt = YoutubeExplode();

  /// Dramas populares precargados para la pantalla de inicio
  static List<DramaModel> getFeaturedDramas() {
    return [
      DramaModel(
        id: 'drama_poder_amantes',
        title: 'El poder viene de mis amantes',
        description:
            'Tras sufrir una cruel humillación pública por parte de su propia familia, despierta un místico Sistema de Apareamiento y Poder donde cada vínculo la hace invencible para reclamar su trono.',
        coverUrl:
            'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop&q=80',
        author: 'NetShort Drama',
        genres: ['Romance', 'Fantasía', 'Venganza', 'Sobrenatural'],
        episodes: [],
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
      DramaModel(
        id: 'drama_segunda_oportunidad',
        title: 'La segunda oportunidad de la dama',
        description:
            'Tras una muerte trágica, viaja al pasado al día de su boda para reescribir su historia y rechazar al hombre que arruinó a su familia.',
        coverUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&auto=format&fit=crop&q=80',
        author: 'GoodShort',
        genres: ['Reencarnación', 'Romance', 'Venganza'],
        episodes: [],
      ),
    ];
  }

  /// Busca dramas en YouTube (playlists o listas de videos)
  static Future<List<DramaModel>> searchDramas(String query) async {
    final List<DramaModel> results = [];
    try {
      final sanitizedQuery = query.trim();
      if (sanitizedQuery.isEmpty) return results;

      // Buscar playlists relacionadas
      final playlistSearch = await _yt.search.searchContent(
        '$sanitizedQuery drama corto capitulo',
      );

      final Map<String, List<EpisodeModel>> groupedByAuthor = {};

      for (var item in playlistSearch) {
        if (item is SearchPlaylist) {
          try {
            final playlist = await _yt.playlists.get(item.id);
            final videoList = await _yt.playlists.getVideos(item.id).take(60).toList();

            if (videoList.isNotEmpty) {
              final episodes = <EpisodeModel>[];
              int epNum = 1;
              for (var v in videoList) {
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
                      : 'Serie de drama vertical con ${episodes.length} episodios.',
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
        } else if (item is SearchVideo) {
          final authorName = item.author.isNotEmpty ? item.author : 'Drama Channel';
          groupedByAuthor.putIfAbsent(authorName, () => []).add(
                EpisodeModel(
                  id: item.id.value,
                  title: item.title,
                  episodeNumber: (groupedByAuthor[authorName]?.length ?? 0) + 1,
                  videoUrl: item.id.value,
                  thumbnailUrl: item.thumbnails.first.url.toString(),
                  duration: _parseDuration(item.duration),
                  isYouTube: true,
                ),
              );
        }
      }

      // Si no encontramos muchas playlists, agrupamos los videos individuales encontrados
      if (results.length < 3) {
        for (var entry in groupedByAuthor.entries) {
          if (entry.value.length >= 2) {
            final episodes = entry.value;
            results.add(
              DramaModel(
                id: 'chan_${entry.key.hashCode}',
                title: '$sanitizedQuery - ${entry.key}',
                description: 'Episodios y capítulos recopilados de ${entry.key}.',
                coverUrl: episodes.first.thumbnailUrl,
                author: entry.key,
                genres: ['Drama Corto', 'Capítulos'],
                episodes: episodes,
              ),
            );
          }
        }
      }

      // Si aún no hay resultados, creamos una serie con los videos directos
      if (results.isEmpty) {
        final videoSearch = await _yt.search.search('$sanitizedQuery drama español');
        final episodes = <EpisodeModel>[];
        int epNum = 1;
        for (var v in videoSearch.take(30)) {
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

        if (episodes.isNotEmpty) {
          results.add(
            DramaModel(
              id: 'search_${query.hashCode}',
              title: query,
              description: 'Capítulos y videos encontrados para "$query".',
              coverUrl: episodes.first.thumbnailUrl,
              author: 'Varios creadores',
              genres: ['Drama', 'Episodios'],
              episodes: episodes,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error buscando dramas: $e');
    }
    return results;
  }

  /// Carga los episodios de un drama si aún no se han cargado
  static Future<DramaModel> loadEpisodesForDrama(DramaModel drama) async {
    if (drama.episodes.isNotEmpty) {
      return drama;
    }

    try {
      final query = '${drama.title} drama capitulo';
      final search = await _yt.search.search(query);

      final episodes = <EpisodeModel>[];
      int epNum = 1;

      for (var v in search.take(45)) {
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

      if (episodes.isNotEmpty) {
        return drama.copyWith(
          episodes: episodes,
          coverUrl: episodes.first.thumbnailUrl,
        );
      }
    } catch (e) {
      debugPrint('Error cargando episodios de ${drama.title}: $e');
    }

    return drama;
  }

  /// Extrae la URL de video directa (.mp4) para reproducirla en video_player
  static Future<String?> extractStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Prioridad 1: Muxed streams (video + audio integrado)
      if (manifest.muxed.isNotEmpty) {
        final muxedStream = manifest.muxed.withHighestBitrate();
        return muxedStream.url.toString();
      }

      // Prioridad 2: Si no hay muxed, videoOnly de mayor resolución
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
