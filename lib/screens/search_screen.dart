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
  final List<String> _suggestions = [
    'El poder viene de mis amantes',
    'El CEO multimillonario',
    'La verdadera heredera',
    'Mi esposo es un dragón',
    'Venganza de amor',
    'ShortMax drama',
    'NetShort español',
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
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<DramaProvider>().search(query.trim());
    }
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
    Navigator.of(context).pop(); // Cerrar loader

    if (readyDrama.episodes.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerticalPlayerScreen(
            drama: readyDrama,
            initialEpisodeIndex: readyDrama.lastWatchedEpisodeIndex,
          ),
        ),
      );
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
            hintText: 'Buscar cualquier drama corto...',
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      _controller.clear();
                      context.read<DramaProvider>().search('');
                      setState(() {});
                    },
                  )
                : null,
          ),
          onSubmitted: _onSearch,
          onChanged: (text) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.redAccent),
            onPressed: () => _onSearch(_controller.text),
          ),
        ],
      ),
      body: Consumer<DramaProvider>(
        builder: (context, prov, child) {
          if (prov.isLoadingSearch) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text('Rastreando episodios del drama...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }

          if (prov.searchResults.isEmpty && prov.currentQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.movie_creation_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'No encontramos episodios para "${prov.currentQuery}"',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Intenta buscar por palabras clave o el título alternativo.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          if (prov.searchResults.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Búsquedas populares',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions.map((sug) {
                      return ActionChip(
                        label: Text(sug, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        backgroundColor: const Color(0xFF1E1E2E),
                        side: const BorderSide(color: Color(0xFF28283E)),
                        onPressed: () {
                          _controller.text = sug;
                          _onSearch(sug);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
            ),
            itemCount: prov.searchResults.length,
            itemBuilder: (context, index) {
              final drama = prov.searchResults[index];
              return DramaCard(
                drama: drama,
                width: double.infinity,
                height: 180,
                onTap: () => _playDrama(context, drama),
              );
            },
          );
        },
      ),
    );
  }
}
