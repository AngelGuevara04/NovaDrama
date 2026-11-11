import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drama_model.dart';
import '../providers/drama_provider.dart';
import '../services/updater_service.dart';
import '../widgets/drama_card.dart';
import '../widgets/update_dialog.dart';
import 'search_screen.dart';
import 'vertical_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Todos';
  final List<String> _categories = [
    'Todos',
    'Tendencias',
    'CEO',
    'Venganza',
    'Fantasía',
    'Romance',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRemoteUpdate(silent: true);
    });
  }

  Future<void> _checkRemoteUpdate({bool silent = false}) async {
    final release = await UpdaterService.checkForUpdate();
    if (release != null && mounted) {
      UpdateDialog.show(context, release);
    } else if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya cuentas con la versión más reciente de NovaDrama (v1.0.0+4).'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _playDrama(DramaModel drama) async {
    final dramaProv = context.read<DramaProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      ),
    );

    final readyDrama = await dramaProv.prepareDramaForPlay(drama);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (readyDrama.episodes.isNotEmpty) {
      final initialEp = drama.lastWatchedEpisodeIndex.clamp(0, readyDrama.episodes.length - 1);
      final initialSec = drama.lastWatchedPositionSeconds;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerticalPlayerScreen(
            drama: readyDrama,
            initialEpisodeIndex: initialEp,
            initialPositionSeconds: initialSec,
          ),
        ),
      );

      if (mounted) {
        dramaProv.loadHistory();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando capítulos del drama... intenta de nuevo.')),
      );
    }
  }

  List<DramaModel> _filterByCategory(List<DramaModel> dramas) {
    if (_selectedCategory == 'Todos' || _selectedCategory == 'Tendencias') {
      return dramas;
    }
    return dramas.where((d) {
      return d.genres.any((g) => g.toLowerCase().contains(_selectedCategory.toLowerCase())) ||
          d.description.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          d.title.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.movie_creation_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'NovaDrama',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Buscar actualizaciones',
            onPressed: () => _checkRemoteUpdate(silent: false),
          ),
        ],
      ),
      body: Consumer<DramaProvider>(
        builder: (context, prov, child) {
          final featured = prov.featured;
          final heroDrama = featured.isNotEmpty ? featured.first : null;
          final filteredDramas = _filterByCategory(featured);

          return RefreshIndicator(
            color: Colors.redAccent,
            backgroundColor: const Color(0xFF1E1E2E),
            onRefresh: () => prov.init(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de búsqueda rápida
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF28283E)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Buscar cualquier drama corto...',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Banner Hero: El poder viene de mis amantes
                  if (heroDrama != null) _buildHeroBanner(heroDrama),

                  const SizedBox(height: 20),

                  // Filtros por Categoría
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.redAccent,
                            backgroundColor: const Color(0xFF1E1E2E),
                            side: BorderSide(
                              color: isSelected ? Colors.redAccent : const Color(0xFF28283E),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Continuar Viendo (Historial con botón para eliminar)
                  if (prov.history.isNotEmpty) ...[
                    _buildSectionHeader('Continuar Viendo', Icons.play_circle_fill),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 230,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: prov.history.length,
                        itemBuilder: (context, index) {
                          final drama = prov.history[index];
                          return Stack(
                            children: [
                              DramaCard(
                                drama: drama,
                                onTap: () => _playDrama(drama),
                              ),
                              Positioned(
                                top: 4,
                                right: 16,
                                child: InkWell(
                                  onTap: () => prov.removeFromHistory(drama.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(180),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white70, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Dramas de Moda (Tendencias)
                  _buildSectionHeader('Dramas Disponibles (${filteredDramas.length})', Icons.local_fire_department),
                  const SizedBox(height: 12),

                  // Cuadrícula completa de todos los dramas disponibles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredDramas.length,
                      itemBuilder: (context, index) {
                        final drama = filteredDramas[index];
                        return DramaCard(
                          drama: drama,
                          width: double.infinity,
                          height: 180,
                          onTap: () => _playDrama(drama),
                        );
                      },
                    ),
                  ),

                  // Mis Favoritos
                  if (prov.favorites.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Mis Favoritos', Icons.favorite),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: prov.favorites.length,
                        itemBuilder: (context, index) {
                          final drama = prov.favorites[index];
                          return DramaCard(
                            drama: drama,
                            onTap: () => _playDrama(drama),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(DramaModel drama) {
    return GestureDetector(
      onTap: () => _playDrama(drama),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: drama.coverUrl,
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => Container(color: const Color(0xFF252538)),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(130),
                      Colors.black.withAlpha(240),
                    ],
                    stops: const [0.2, 0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DRAMA DESTACADO',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      drama.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      drama.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => _playDrama(drama),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Ver ahora gratis', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
