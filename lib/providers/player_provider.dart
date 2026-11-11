import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/drama_model.dart';
import '../models/episode_model.dart';
import '../services/drama_service.dart';
import '../services/storage_service.dart';

enum VideoFitMode {
  focusDramaRight, // Enfoca la mitad derecha (elimina el fondo de pantalla partida)
  coverCenter,     // Pantalla completa centrado
  contain,         // Original completo con barras negras
}

class PlayerProvider extends ChangeNotifier {
  DramaModel? _currentDrama;
  int _currentIndex = 0;
  VideoPlayerController? _controller;
  String? _currentLoadedVideoId;
  bool _isLoading = false;
  String? _errorMessage;
  double _playbackSpeed = 1.0;
  bool _showControls = true;
  VideoFitMode _fitMode = VideoFitMode.focusDramaRight;
  Timer? _controlsTimer;
  Timer? _progressSaveTimer;

  DramaModel? get currentDrama => _currentDrama;
  int get currentIndex => _currentIndex;
  VideoPlayerController? get controller => _controller;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get playbackSpeed => _playbackSpeed;
  bool get showControls => _showControls;
  VideoFitMode get fitMode => _fitMode;

  EpisodeModel? get currentEpisode {
    if (_currentDrama == null || _currentDrama!.episodes.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _currentDrama!.episodes.length) return null;
    return _currentDrama!.episodes[_currentIndex];
  }

  int get totalEpisodes => _currentDrama?.episodes.length ?? 0;

  void cycleFitMode() {
    switch (_fitMode) {
      case VideoFitMode.focusDramaRight:
        _fitMode = VideoFitMode.coverCenter;
        break;
      case VideoFitMode.coverCenter:
        _fitMode = VideoFitMode.contain;
        break;
      case VideoFitMode.contain:
        _fitMode = VideoFitMode.focusDramaRight;
        break;
    }
    notifyListeners();
  }

  String get fitModeLabel {
    switch (_fitMode) {
      case VideoFitMode.focusDramaRight:
        return 'Enfocar Drama (Derecha)';
      case VideoFitMode.coverCenter:
        return 'Pantalla Completa';
      case VideoFitMode.contain:
        return 'Original Completo';
    }
  }

  Future<void> initDrama(
    DramaModel drama, {
    int initialIndex = 0,
    int initialPositionSeconds = 0,
  }) async {
    _currentDrama = drama;
    _currentIndex = initialIndex.clamp(0, (drama.episodes.length - 1).clamp(0, 9999));
    notifyListeners();

    await WakelockPlus.enable();
    await _loadEpisode(_currentIndex, initialSeekSeconds: initialPositionSeconds);
    _startProgressTimer();
  }

  Future<void> _loadEpisode(int index, {int initialSeekSeconds = 0}) async {
    if (_currentDrama == null || index < 0 || index >= _currentDrama!.episodes.length) {
      return;
    }

    _currentIndex = index;
    _errorMessage = null;
    final episode = _currentDrama!.episodes[index];

    // Si ya tenemos el video cargado (mismo videoUrl en video compilado), solo hacemos seek rápido
    if (_controller != null &&
        _controller!.value.isInitialized &&
        _currentLoadedVideoId == episode.videoUrl) {
      final targetSeconds = initialSeekSeconds > 0 ? initialSeekSeconds : episode.startSeconds;
      await _controller!.seekTo(Duration(seconds: targetSeconds));
      if (!_controller!.value.isPlaying) {
        await _controller!.play();
      }
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Limpiar controlador anterior
    final oldController = _controller;
    _controller = null;
    await oldController?.dispose();

    try {
      String? streamUrl = episode.directStreamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        if (episode.isYouTube) {
          streamUrl = await DramaService.extractStreamUrl(episode.videoUrl);
        } else {
          streamUrl = episode.videoUrl;
        }
      }

      if (streamUrl == null) {
        _errorMessage = 'No se pudo obtener el video del capítulo ${episode.episodeNumber}.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );

      await controller.initialize();
      await controller.setPlaybackSpeed(_playbackSpeed);

      final targetSeconds = initialSeekSeconds > 0 ? initialSeekSeconds : episode.startSeconds;
      if (targetSeconds > 0) {
        await controller.seekTo(Duration(seconds: targetSeconds));
      }

      await controller.play();

      controller.addListener(_videoListener);

      _controller = controller;
      _currentLoadedVideoId = episode.videoUrl;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error inicializando video: $e');
      _errorMessage = 'Error al reproducir el capítulo: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _videoListener() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final ep = currentEpisode;
    if (ep != null && ep.endSeconds > 0) {
      if (_controller!.value.position.inSeconds >= ep.endSeconds) {
        if (hasNextEpisode) {
          nextEpisode();
        }
        return;
      }
    }

    if (_controller!.value.position >= _controller!.value.duration &&
        _controller!.value.duration > Duration.zero) {
      if (hasNextEpisode) {
        nextEpisode();
      }
    }
  }

  bool get hasNextEpisode =>
      _currentDrama != null && _currentIndex < _currentDrama!.episodes.length - 1;

  bool get hasPreviousEpisode => _currentDrama != null && _currentIndex > 0;

  void nextEpisode() {
    if (hasNextEpisode) {
      _loadEpisode(_currentIndex + 1);
    }
  }

  void previousEpisode() {
    if (hasPreviousEpisode) {
      _loadEpisode(_currentIndex - 1);
    }
  }

  void jumpToEpisode(int index) {
    if (index != _currentIndex) {
      _loadEpisode(index);
    }
  }

  void togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _saveCurrentProgress();
    } else {
      _controller!.play();
    }
    notifyListeners();
  }

  void forward10Seconds() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final current = _controller!.value.position;
    final max = _controller!.value.duration;
    final target = current + const Duration(seconds: 10);
    _controller!.seekTo(target < max ? target : max);
    notifyListeners();
  }

  void rewind10Seconds() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final current = _controller!.value.position;
    final target = current - const Duration(seconds: 10);
    _controller!.seekTo(target > Duration.zero ? target : Duration.zero);
    notifyListeners();
  }

  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    _controller?.setPlaybackSpeed(speed);
    notifyListeners();
  }

  void seekTo(Duration position) {
    _controller?.seekTo(position);
  }

  void seekRelativeInEpisode(Duration episodePosition) {
    final ep = currentEpisode;
    if (ep != null && ep.startSeconds > 0) {
      final absoluteSeconds = ep.startSeconds + episodePosition.inSeconds;
      _controller?.seekTo(Duration(seconds: absoluteSeconds));
    } else {
      _controller?.seekTo(episodePosition);
    }
  }

  Duration get episodeCurrentPosition {
    if (_controller == null || !_controller!.value.isInitialized) return Duration.zero;
    final ep = currentEpisode;
    if (ep != null && ep.startSeconds > 0) {
      final posSec = _controller!.value.position.inSeconds - ep.startSeconds;
      return Duration(seconds: posSec.clamp(0, ep.duration.inSeconds));
    }
    return _controller!.value.position;
  }

  Duration get episodeTotalDuration {
    final ep = currentEpisode;
    if (ep != null && ep.duration > Duration.zero) {
      return ep.duration;
    }
    if (_controller != null && _controller!.value.isInitialized) {
      return _controller!.value.duration;
    }
    return Duration.zero;
  }

  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();

    _controlsTimer?.cancel();
    if (_showControls) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        _showControls = false;
        notifyListeners();
      });
    }
  }

  void _startProgressTimer() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveCurrentProgress();
    });
  }

  void _saveCurrentProgress() {
    if (_currentDrama == null || _controller == null || !_controller!.value.isInitialized) return;
    final pos = _controller!.value.position.inSeconds;
    if (pos > 0) {
      StorageService.saveProgress(
        drama: _currentDrama!,
        episodeIndex: _currentIndex,
        positionSeconds: pos,
      );
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    _saveCurrentProgress();
    _controller?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
}
