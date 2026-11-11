import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/drama_model.dart';

class DramaCard extends StatelessWidget {
  final DramaModel drama;
  final VoidCallback onTap;
  final double width;
  final double height;

  const DramaCard({
    super.key,
    required this.drama,
    required this.onTap,
    this.width = 140,
    this.height = 210,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: drama.coverUrl,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF252538),
                      child: const Center(
                        child: Icon(LucideIcons.film, color: Colors.white24, size: 32),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF252538),
                      child: const Center(
                        child: Icon(LucideIcons.imageOff, color: Colors.white24, size: 32),
                      ),
                    ),
                  ),
                ),
                // Gradiente inferior
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                // Badge de episodios o autor
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          drama.totalEpisodes > 0 ? '${drama.totalEpisodes} Eps' : 'Minidrama',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(LucideIcons.playCircle, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Título
            Text(
              drama.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.2,
              ),
            ),
            if (drama.genres.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                drama.genres.first,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
