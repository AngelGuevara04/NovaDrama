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

  bool isFavorite(String dramaId) {
    return _favorites.any((d) => d.id == dramaId);
  }

  Future<void> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      _searchResults = [];
      _currentQuery = '';
      notifyListeners();
      return;
    }

    _isLoadingSearch = true;
    _currentQuery = cleanQuery;
    notifyListeners();

    try {
      _searchResults = await DramaService.searchDramas(cleanQuery);
    } catch (e) {
      debugPrint('Error en DramaProvider.search: $e');
      _searchResults = [];
    } finally {
      _isLoadingSearch = false;
      notifyListeners();
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
