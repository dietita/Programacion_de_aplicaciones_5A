import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import 'pokeball_painter.dart';

class PokemonCard extends StatelessWidget {
  final PokemonListItem item;
  final VoidCallback onTap;
  const PokemonCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: PokeballDecoration(
                size: 110,
                color: Colors.grey.withOpacity(0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.number,
                    style: const TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Hero(
                        tag: 'poke-${item.id}',
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.catching_pokemon,
                            size: 60,
                            color: Colors.black12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF313131),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
