import 'package:flutter/material.dart';
import '../models/drama_model.dart';
import '../services/drama_service.dart';
import '../services/storage_service.dart';

class DramaProvider extends ChangeNotifier {
  List<DramaModel> _featured = [];
  List<DramaModel> _searchResults = [];
  List<DramaModel> _favorites = [];
  List<DramaModel> _history = [];
  bool _isLoadingSearch = false;
  String _currentQuery = '';

  List<DramaModel> get featured => _featured;
  List<DramaModel> get searchResults => _searchResults;
  List<DramaModel> get favorites => _favorites;
  List<DramaModel> get history => _history;
  bool get isLoadingSearch => _isLoadingSearch;
  String get currentQuery => _currentQuery;

  DramaProvider() {
    init();
  }

  Future<void> init() async {
    _featured = DramaService.getFeaturedDramas();
    await loadFavorites();
    await loadHistory();
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    _favorites = await StorageService.getFavorites();
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _history = await StorageService.getHistory();
    notifyListeners();
  }

  Future<void> toggleFavorite(DramaModel drama) async {
    await StorageService.toggleFavorite(drama);
    await loadFavorites();
  }

  Future<void> removeFromHistory(String dramaId) async {
    await StorageService.removeFromHistory(dramaId);
    await loadHistory();
  }

  bool isFavorite(String dramaId) {
    return _favorites.any((d) => d.id == dramaId);
  }

  /// Filtra coincidencias locales al instante mientras el usuario teclea
  List<DramaModel> getLocalMatches(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final Set<String> seenIds = {};
    final List<DramaModel> matches = [];

    final allSources = [..._history, ..._favorites, ..._featured];
    for (var d in allSources) {
      if (!seenIds.contains(d.id)) {
        final title = d.title.toLowerCase();
        final desc = d.description.toLowerCase();
        final genres = d.genres.map((g) => g.toLowerCase()).join(' ');
        if (title.contains(clean) || desc.contains(clean) || genres.contains(clean)) {
          seenIds.add(d.id);
          matches.add(d);
        }
      }
    }
    return matches;
  }

  /// Búsqueda reactiva completa
  Future<void> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      _searchResults = [];
      _currentQuery = '';
      _isLoadingSearch = false;
      notifyListeners();
      return;
    }

    _currentQuery = cleanQuery;
    // Mostrar de inmediato las coincidencias locales
    _searchResults = getLocalMatches(cleanQuery);
    _isLoadingSearch = true;
    notifyListeners();

    try {
      final remoteResults = await DramaService.searchDramas(cleanQuery);

      if (_currentQuery == cleanQuery) {
        final Set<String> seenIds = _searchResults.map((d) => d.id).toSet();
        for (var r in remoteResults) {
          if (!seenIds.contains(r.id)) {
            seenIds.add(r.id);
            _searchResults.add(r);
          }
        }
      }
    } catch (e) {
      debugPrint('Error en DramaProvider.search: $e');
    } finally {
      if (_currentQuery == cleanQuery) {
        _isLoadingSearch = false;
        notifyListeners();
      }
    }
  }

  Future<DramaModel> prepareDramaForPlay(DramaModel drama) async {
    if (drama.episodes.isEmpty) {
      final loaded = await DramaService.loadEpisodesForDrama(drama);
      return loaded.copyWith(
        lastWatchedEpisodeIndex: drama.lastWatchedEpisodeIndex,
        lastWatchedPositionSeconds: drama.lastWatchedPositionSeconds,
      );
    }
    return drama;
  }
}
