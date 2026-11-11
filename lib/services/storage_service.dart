import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/drama_model.dart';

class StorageService {
  static const String _keyFavorites = 'novadrama_favorites';
  static const String _keyHistory = 'novadrama_history';

  static Future<List<DramaModel>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyFavorites) ?? [];
    return data.map((item) => DramaModel.fromJson(json.decode(item))).toList();
  }

  static Future<void> toggleFavorite(DramaModel drama) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getFavorites();
    final index = list.indexWhere((d) => d.id == drama.id);

    if (index >= 0) {
      list.removeAt(index);
    } else {
      list.insert(0, drama);
    }

    final rawList = list.map((d) => json.encode(d.toJson())).toList();
    await prefs.setStringList(_keyFavorites, rawList);
  }

  static Future<bool> isFavorite(String dramaId) async {
    final list = await getFavorites();
    return list.any((d) => d.id == dramaId);
  }

  static Future<List<DramaModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyHistory) ?? [];
    return data.map((item) => DramaModel.fromJson(json.decode(item))).toList();
  }

  static Future<void> saveProgress({
    required DramaModel drama,
    required int episodeIndex,
    required int positionSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    final updatedDrama = drama.copyWith(
      lastWatchedAt: DateTime.now(),
      lastWatchedEpisodeIndex: episodeIndex,
      lastWatchedPositionSeconds: positionSeconds,
    );

    history.removeWhere((d) => d.id == drama.id);
    history.insert(0, updatedDrama);

    // Guardar maximo 50 en historial
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final rawList = history.map((d) => json.encode(d.toJson())).toList();
    await prefs.setStringList(_keyHistory, rawList);
  }

  static Future<void> removeFromHistory(String dramaId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.removeWhere((d) => d.id == dramaId);
    final rawList = history.map((d) => json.encode(d.toJson())).toList();
    await prefs.setStringList(_keyHistory, rawList);
  }
}
