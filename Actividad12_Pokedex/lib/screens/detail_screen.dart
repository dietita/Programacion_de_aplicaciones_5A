import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../utils/type_colors.dart';
import '../widgets/pokeball_painter.dart';
import '../widgets/type_chip.dart';

/// Pantalla que obtiene UN Pokémon de https://pokeapi.co/api/v2/pokemon/{id}/
/// con Dio, lo convierte a la clase Pokemon y lo muestra.
class DetailScreen extends StatefulWidget {
  final int initialId;
  const DetailScreen({super.key, this.initialId = 1});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final PokemonService _service = PokemonService();
  late int _id;
  late Future<Pokemon> _future;

  @override
  void initState() {
    super.initState();
    _id = widget.initialId;
    _load();
  }

  void _load() {
    _future = _service.getPokemon(_id.toString());
  }

  void _goTo(int id) {
    if (id < 1 || id > 1025) return;
    setState(() {
      _id = id;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pokemon>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFE3350D),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(_load),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildDetail(snapshot.data!);
      },
    );
  }

  Widget _buildDetail(Pokemon p) {
    final color = TypeColors.of(p.types.first);

    return Scaffold(
      backgroundColor: color,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('POKÉDEX',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          IconButton(
            tooltip: 'Anterior',
            onPressed: p.id > 1 ? () => _goTo(p.id - 1) : null,
            icon: const Icon(Icons.chevron_left, size: 30),
          ),
          IconButton(
            tooltip: 'Siguiente',
            onPressed: () => _goTo(p.id + 1),
            icon: const Icon(Icons.chevron_right, size: 30),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ---------- Encabezado ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: p.types
                              .map((t) => TypeChip(type: t, light: true))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    p.number,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            // ---------- Imagen ----------
            SizedBox(
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const PokeballDecoration(size: 220),
                  Hero(
                    tag: 'poke-${p.id}',
                    child: Image.network(
                      p.imageUrl,
                      height: 210,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.catching_pokemon,
                        size: 120,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ---------- Tarjeta de información ----------
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Información', color),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _infoBox(Icons.height, 'Altura',
                              '${p.heightMeters.toStringAsFixed(1)} m'),
                          _infoBox(Icons.fitness_center, 'Peso',
                              '${p.weightKg.toStringAsFixed(1)} kg'),
                          _infoBox(Icons.star, 'Exp. base',
                              '${p.baseExperience}'),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('Habilidades', color),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: p.abilities
                            .map((a) => Chip(
                                  label: Text(a.replaceAll('-', ' ')),
                                  backgroundColor: color.withOpacity(0.12),
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                    color: color.computeLuminance() > 0.6
                                        ? Colors.black87
                                        : color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('Estadísticas base', color),
                      const SizedBox(height: 10),
                      ...p.stats.map((s) => _statRow(s, color)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) => Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: color.computeLuminance() > 0.6 ? Colors.black87 : color,
        ),
      );

  Widget _infoBox(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black45),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label,
                style: const TextStyle(color: Colors.black45, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _statRow(PokemonStat s, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(s.label,
                style: const TextStyle(
                    color: Colors.black54, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 36,
            child: Text('${s.value}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (s.value / 255).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 9,
                  backgroundColor: const Color(0xFFEDEDED),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
