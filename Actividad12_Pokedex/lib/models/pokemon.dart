/// Clase personalizada en Dart que representa la respuesta de
/// https://pokeapi.co/api/v2/pokemon/{id}/
class Pokemon {
  final int id;
  final String name;
  final int height; // decímetros
  final int weight; // hectogramos
  final int baseExperience;
  final String imageUrl;
  final String spriteUrl;
  final List<String> types;
  final List<String> abilities;
  final List<PokemonStat> stats;

  Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.imageUrl,
    required this.spriteUrl,
    required this.types,
    required this.abilities,
    required this.stats,
  });

  /// Convierte el JSON de la API en un objeto Pokemon
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'] as Map<String, dynamic>;
    final other = sprites['other'] as Map<String, dynamic>?;
    final artwork = other?['official-artwork']?['front_default'] as String?;

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int,
      weight: json['weight'] as int,
      baseExperience: (json['base_experience'] ?? 0) as int,
      imageUrl: artwork ?? (sprites['front_default'] as String? ?? ''),
      spriteUrl: sprites['front_default'] as String? ?? '',
      types: (json['types'] as List)
          .map((t) => t['type']['name'] as String)
          .toList(),
      abilities: (json['abilities'] as List)
          .map((a) => a['ability']['name'] as String)
          .toList(),
      stats: (json['stats'] as List)
          .map((s) => PokemonStat.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  String get displayName => name[0].toUpperCase() + name.substring(1);
  String get number => '#${id.toString().padLeft(4, '0')}';
  double get heightMeters => height / 10;
  double get weightKg => weight / 10;
}

class PokemonStat {
  final String name;
  final int value;

  PokemonStat({required this.name, required this.value});

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      name: json['stat']['name'] as String,
      value: json['base_stat'] as int,
    );
  }

  String get label {
    switch (name) {
      case 'hp':
        return 'PS';
      case 'attack':
        return 'Ataque';
      case 'defense':
        return 'Defensa';
      case 'special-attack':
        return 'At. Esp.';
      case 'special-defense':
        return 'Def. Esp.';
      case 'speed':
        return 'Velocidad';
      default:
        return name;
    }
  }
}

/// Elemento ligero de la lista /pokemon?limit=N
class PokemonListItem {
  final int id;
  final String name;

  PokemonListItem({required this.id, required this.name});

  factory PokemonListItem.fromJson(Map<String, dynamic> json) {
    // url: https://pokeapi.co/api/v2/pokemon/25/
    final url = json['url'] as String;
    final parts = url.split('/')..removeWhere((p) => p.isEmpty);
    return PokemonListItem(id: int.parse(parts.last), name: json['name']);
  }

  String get displayName => name[0].toUpperCase() + name.substring(1);
  String get number => '#${id.toString().padLeft(4, '0')}';
  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}
