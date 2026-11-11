import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  @override
  void initState() {
    super.initState();
    _playerProvider = PlayerProvider();
    _playerProvider.initDrama(widget.drama, initialIndex: widget.initialEpisodeIndex);
  }

  @override
  void dispose() {
    _playerProvider.dispose();
    super.dispose();
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
                    icon: const Icon(LucideIcons.x, color: Colors.white70),
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
              trailing: isSelected ? const Icon(LucideIcons.check, color: Colors.redAccent) : null,
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
                  // Video centrado
                  if (isInitialized)
                    Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
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

                  // Mensaje de error si falla
                  if (player.errorMessage != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 40),
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
                                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
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
                                  // Botón de Favorito
                                  Consumer<DramaProvider>(
                                    builder: (context, dramaProv, _) {
                                      final isFav = dramaProv.isFavorite(widget.drama.id);
                                      return IconButton(
                                        icon: Icon(
                                          isFav ? LucideIcons.heart : LucideIcons.heart,
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
                                  child: const Icon(LucideIcons.play, color: Colors.white, size: 48),
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
                                  // Botonera de acciones (Episodios, Velocidad)
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
                                        icon: const Icon(LucideIcons.list, size: 16),
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
                                        icon: const Icon(LucideIcons.gauge, size: 16),
                                        label: Text('${player.playbackSpeed}x'),
                                      ),
                                      const Spacer(),
                                      // Indicador de gesto
                                      const Row(
                                        children: [
                                          Icon(LucideIcons.arrowUp, color: Colors.white54, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'Desliza para siguiente',
                                            style: TextStyle(color: Colors.white54, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Barra de progreso y tiempo
                                  if (isInitialized) ...[
                                    Row(
                                      children: [
                                        Text(
                                          _formatDuration(controller.value.position),
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
                                              value: controller.value.position.inSeconds
                                                  .toDouble()
                                                  .clamp(0.0, controller.value.duration.inSeconds.toDouble()),
                                              max: controller.value.duration.inSeconds.toDouble() > 0
                                                  ? controller.value.duration.inSeconds.toDouble()
                                                  : 1.0,
                                              onChanged: (val) {
                                                player.seekTo(Duration(seconds: val.toInt()));
                                              },
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(controller.value.duration),
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
