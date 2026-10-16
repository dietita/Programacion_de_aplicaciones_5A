import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokeball_painter.dart';
import '../widgets/pokemon_card.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PokemonService _service = PokemonService();
  final TextEditingController _search = TextEditingController();
  late Future<List<PokemonListItem>> _future;
  String _filter = '';

  static const Color red = Color(0xFFE3350D);

  @override
  void initState() {
    super.initState();
    _future = _service.getPokemonList(limit: 151);
  }

  void _openDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(initialId: id)),
    );
  }

  void _submitSearch(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    final asNumber = int.tryParse(v);
    if (asNumber != null) {
      _openDetail(asNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          FutureBuilder<List<PokemonListItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: red)),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: _ErrorView(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {
                      _future = _service.getPokemonList(limit: 151);
                    }),
                  ),
                );
              }
              final list = snapshot.data!
                  .where((p) =>
                      p.name.contains(_filter.toLowerCase()) ||
                      p.id.toString() == _filter)
                  .toList();

              if (list.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Sin resultados')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => PokemonCard(
                      item: list[i],
                      onTap: () => _openDetail(list[i].id),
                    ),
                    childCount: list.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: red,
        foregroundColor: Colors.white,
        onPressed: () => _openDetail(1),
        icon: const Icon(Icons.catching_pokemon),
        label: const Text('Ver #0001',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE3350D), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -40,
            top: -30,
            child: PokeballDecoration(size: 220),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.catching_pokemon,
                          color: Colors.white, size: 36),
                      const SizedBox(width: 10),
                      Text(
                        'POKÉDEX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(2, 3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Primera generación · Datos de PokeAPI',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _filter = v.trim()),
                    onSubmitted: _submitSearch,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o número',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _filter.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                setState(() => _filter = '');
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 60, color: Colors.black26),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
