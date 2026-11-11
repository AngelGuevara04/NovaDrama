import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drama_model.dart';
import '../providers/drama_provider.dart';
import '../widgets/drama_card.dart';
import 'vertical_player_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  final List<String> _suggestions = [
    'El poder viene de mis amantes',
    'El CEO multimillonario',
    'La verdadera heredera',
    'Mi esposo es un dragón',
    'Matrimonio relámpago',
    'Venganza de amor',
    'Alfa supremo lobo',
    'ShortMax drama',
    'NetShort español',
    'DramaBox serie',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DramaProvider>().search(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final prov = context.read<DramaProvider>();

    if (query.trim().isEmpty) {
      prov.search('');
      setState(() {});
      return;
    }

    // Filtrar de inmediato en memoria
    prov.search(query.trim());

    // Esperar 400ms tras teclear para buscar más en red
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _controller.text.trim().isNotEmpty) {
        prov.search(_controller.text.trim());
      }
    });
    setState(() {});
  }

  Future<void> _playDrama(BuildContext context, DramaModel drama) async {
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
        const SnackBar(content: Text('No se pudieron encontrar capítulos reproducibles para este drama.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161622),
        elevation: 0,
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery == null,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Escribe para buscar cualquier drama...',
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      _controller.clear();
                      _onQueryChanged('');
                    },
                  )
                : null,
          ),
          onChanged: _onQueryChanged,
          onSubmitted: (query) => _onQueryChanged(query),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.redAccent),
            onPressed: () => _onQueryChanged(_controller.text),
          ),
        ],
      ),
      body: Consumer<DramaProvider>(
        builder: (context, prov, child) {
          final results = prov.searchResults;

          if (results.isEmpty && prov.currentQuery.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dramas y temas populares',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions.map((sug) {
                      return ActionChip(
                        label: Text(sug, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        backgroundColor: const Color(0xFF1E1E2E),
                        side: const BorderSide(color: Color(0xFF28283E)),
                        onPressed: () {
                          _controller.text = sug;
                          _onQueryChanged(sug);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }

          if (results.isEmpty && !prov.isLoadingSearch) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.movie_creation_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'No encontramos coincidencias para "${prov.currentQuery}"',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prueba con otra palabra clave como "CEO", "venganza" o "matrimonio".',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de estado de resultados
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Disponibles (${results.length})',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    if (prov.isLoadingSearch)
                      const Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                          ),
                          SizedBox(width: 8),
                          Text('Buscando más...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                  ],
                ),
              ),

              // Rejilla de todos los dramas encontrados
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final drama = results[index];
                    return DramaCard(
                      drama: drama,
                      width: double.infinity,
                      height: 180,
                      onTap: () => _playDrama(context, drama),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
