import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/drama_model.dart';
import '../providers/drama_provider.dart';
import '../providers/player_provider.dart';

class VerticalPlayerScreen extends StatefulWidget {
  final DramaModel drama;
  final int initialEpisodeIndex;

  const VerticalPlayerScreen({
    super.key,
    required this.drama,
    this.initialEpisodeIndex = 0,
  });

  @override
  State<VerticalPlayerScreen> createState() => _VerticalPlayerScreenState();
}

class _VerticalPlayerScreenState extends State<VerticalPlayerScreen> {
  late PlayerProvider _playerProvider;
  bool _showForwardFeedback = false;
  bool _showRewindFeedback = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _playerProvider = PlayerProvider();
    _playerProvider.initDrama(widget.drama, initialIndex: widget.initialEpisodeIndex);
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _playerProvider.dispose();
    super.dispose();
  }

  void _triggerDoubleTap(TapDownDetails details, double screenWidth) {
    _feedbackTimer?.cancel();
    if (details.globalPosition.dx > screenWidth / 2) {
      // Mitad derecha: adelantar 10 segundos
      _playerProvider.forward10Seconds();
      setState(() {
        _showForwardFeedback = true;
        _showRewindFeedback = false;
      });
    } else {
      // Mitad izquierda: retroceder 10 segundos
      _playerProvider.rewind10Seconds();
      setState(() {
        _showRewindFeedback = true;
        _showForwardFeedback = false;
      });
    }

    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showForwardFeedback = false;
          _showRewindFeedback = false;
        });
      }
    });
  }

  void _showEpisodesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Episodios (${widget.drama.totalEpisodes})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: widget.drama.totalEpisodes,
                  itemBuilder: (context, index) {
                    final isCurrent = _playerProvider.currentIndex == index;
                    return InkWell(
                      onTap: () {
                        _playerProvider.jumpToEpisode(index);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.redAccent : const Color(0xFF28283E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent ? Colors.white : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
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
      },
    );
  }

  void _showSpeedDialog() {
    final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Velocidad de reproducción', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: speeds.map((speed) {
            final isSelected = _playerProvider.playbackSpeed == speed;
            return ListTile(
              title: Text('${speed}x', style: TextStyle(color: isSelected ? Colors.redAccent : Colors.white)),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.redAccent) : null,
              onTap: () {
                _playerProvider.setPlaybackSpeed(speed);
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ChangeNotifierProvider.value(
      value: _playerProvider,
      child: Consumer<PlayerProvider>(
        builder: (context, player, child) {
          final controller = player.controller;
          final isInitialized = controller != null && controller.value.isInitialized;

          return Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              onTap: () => player.toggleControls(),
              onDoubleTapDown: (details) => _triggerDoubleTap(details, screenWidth),
              onVerticalDragEnd: (details) {
                // Deslizar hacia arriba = siguiente capítulo
                if (details.primaryVelocity! < -300) {
                  if (player.hasNextEpisode) {
                    player.nextEpisode();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Estás en el último episodio.')),
                    );
                  }
                }
                // Deslizar hacia abajo = capítulo anterior
                else if (details.primaryVelocity! > 300) {
                  if (player.hasPreviousEpisode) {
                    player.previousEpisode();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Estás en el primer episodio.')),
                    );
                  }
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video escalado (Full Screen vertical o Contain)
                  if (isInitialized)
                    SizedBox.expand(
                      child: FittedBox(
                        fit: player.videoFit,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    ),

                  // Animación de carga intermedia
                  if (player.isLoading)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.redAccent),
                            SizedBox(height: 12),
                            Text('Cargando capítulo...', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),

                  // Indicador de avance (+10s) con doble toque
                  if (_showForwardFeedback)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(right: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fast_forward, color: Colors.white, size: 28),
                            SizedBox(width: 6),
                            Text(
                              '+10s',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Indicador de retroceso (-10s) con doble toque
                  if (_showRewindFeedback)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(left: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fast_rewind, color: Colors.white, size: 28),
                            SizedBox(width: 6),
                            Text(
                              '-10s',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Mensaje de error si falla
                  if (player.errorMessage != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E).withAlpha(230),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              player.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => player.jumpToEpisode(player.currentIndex),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Controles superpuestos (fade out/in)
                  AnimatedOpacity(
                    opacity: player.showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: !player.showControls,
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Barra Superior
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.drama.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Capítulo ${player.currentIndex + 1} de ${widget.drama.totalEpisodes}',
                                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botón de Modo Pantalla Completa / Ajuste
                                  IconButton(
                                    icon: Icon(
                                      player.videoFit == BoxFit.cover ? Icons.fullscreen_exit : Icons.fullscreen,
                                      color: Colors.white,
                                    ),
                                    tooltip: player.videoFit == BoxFit.cover
                                        ? 'Ver original centrado'
                                        : 'Llenar pantalla completa',
                                    onPressed: () => player.toggleVideoFit(),
                                  ),
                                  // Botón de Favorito
                                  Consumer<DramaProvider>(
                                    builder: (context, dramaProv, _) {
                                      final isFav = dramaProv.isFavorite(widget.drama.id);
                                      return IconButton(
                                        icon: Icon(
                                          isFav ? Icons.favorite : Icons.favorite_border,
                                          color: isFav ? Colors.redAccent : Colors.white70,
                                        ),
                                        onPressed: () => dramaProv.toggleFavorite(widget.drama),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Botón Central Play/Pause grande (si está en pausa)
                            if (isInitialized && !controller.value.isPlaying)
                              GestureDetector(
                                onTap: () => player.togglePlayPause(),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white30, width: 2),
                                  ),
                                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                                ),
                              ),

                            // Barra Inferior de controles y progreso
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Botonera de acciones (Episodios, Velocidad, Ajuste)
                                  Row(
                                    children: [
                                      // Botón Lista de Episodios
                                      ElevatedButton.icon(
                                        onPressed: _showEpisodesBottomSheet,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.format_list_numbered, size: 16),
                                        label: Text(
                                          'Cap. ${player.currentIndex + 1}/${widget.drama.totalEpisodes}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Botón Velocidad
                                      ElevatedButton.icon(
                                        onPressed: _showSpeedDialog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.speed, size: 16),
                                        label: Text('${player.playbackSpeed}x'),
                                      ),
                                      const SizedBox(width: 8),
                                      // Botón de ajuste de escala
                                      InkWell(
                                        onTap: () => player.toggleVideoFit(),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            player.videoFit == BoxFit.cover ? 'Pantalla Completa' : 'Original',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Indicador de gesto
                                      const Row(
                                        children: [
                                          Icon(Icons.touch_app, color: Colors.white54, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            '2x tap: ±10s',
                                            style: TextStyle(color: Colors.white54, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Barra de progreso y tiempo relativo del capítulo
                                  if (isInitialized) ...[
                                    Row(
                                      children: [
                                        Text(
                                          _formatDuration(player.episodeCurrentPosition),
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              activeTrackColor: Colors.redAccent,
                                              inactiveTrackColor: Colors.white24,
                                              thumbColor: Colors.redAccent,
                                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                            ),
                                            child: Slider(
                                              value: player.episodeCurrentPosition.inSeconds
                                                  .toDouble()
                                                  .clamp(0.0, player.episodeTotalDuration.inSeconds.toDouble()),
                                              max: player.episodeTotalDuration.inSeconds.toDouble() > 0
                                                  ? player.episodeTotalDuration.inSeconds.toDouble()
                                                  : 1.0,
                                              onChanged: (val) {
                                                player.seekRelativeInEpisode(Duration(seconds: val.toInt()));
                                              },
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(player.episodeTotalDuration),
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
