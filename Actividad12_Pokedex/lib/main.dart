import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// ============================================================================
//  POKÉMON — Práctica académica 02: Flutter consumiendo una API (PokeAPI + Dio)
//
//  1. Dio en pubspec.yaml
//  2. Peticiones de red con Future + Dio         → clase PokeApi
//  3. Respuesta JSON → clases Dart               → Pokemon, Species, TypeInfo
//  4. Obtener y mostrar los datos con Flutter    → HomePage, DetailPage
// ============================================================================

void main() => runApp(const PokemonApp());

const kRed = Color(0xFFE3350D);
const kNavy = Color(0xFF0B1C3F);
const kNavy2 = Color(0xFF15326B);
const kBlue = Color(0xFF2A75BB);
const kYellow = Color(0xFFFFCB05);

/// Logo oficial (imagen que indicaste, de Wikimedia) en alta resolución.
const kLogoUrl =
    'https://upload.wikimedia.org/wikipedia/commons/thumb/9/98/International_Pok%C3%A9mon_logo.svg/960px-International_Pok%C3%A9mon_logo.svg.png';

/// Si pones tu GIF/PNG animado de Pikachu saludando en esta ruta,
/// el header lo usa automáticamente (ver instrucciones).
const kPikachuAsset = 'assets/pikachu_saludo.gif';
const kRedDark = Color(0xFF8E1408);
const kInk = Color(0xFF14161F);
const kBg = Color(0xFFF3F4F8);

class PokemonApp extends StatelessWidget {
  const PokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kRed),
        scaffoldBackgroundColor: kBg,
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================================
//  MODELOS (JSON → clases Dart)
// ============================================================================

String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String pretty(String s) => cap(s.replaceAll('-', ' '));

int idFromUrl(String url) {
  final parts = url.split('/')..removeWhere((p) => p.isEmpty);
  return int.parse(parts.last);
}

/// Sprite animado (cada Pokémon tiene su propio movimiento).
String animatedSprite(int id) =>
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/$id.gif';

const int kMaxPokemon = 1025;

class Region {
  final String name;
  final int from;
  final int to;
  const Region(this.name, this.from, this.to);
}

const List<Region> kRegions = [
  Region('Todas', 1, 1025),
  Region('Kanto', 1, 151),
  Region('Johto', 152, 251),
  Region('Hoenn', 252, 386),
  Region('Sinnoh', 387, 493),
  Region('Teselia', 494, 649),
  Region('Kalos', 650, 721),
  Region('Alola', 722, 809),
  Region('Galar', 810, 905),
  Region('Paldea', 906, 1025),
];

String artwork(int id) =>
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

class Ability {
  final String name;
  final bool hidden;
  const Ability(this.name, this.hidden);
}

class PokemonStat {
  final String name;
  final int value;
  const PokemonStat(this.name, this.value);

  String get label => const {
        'hp': 'PS',
        'attack': 'Ataque',
        'defense': 'Defensa',
        'special-attack': 'At. Especial',
        'special-defense': 'Def. Especial',
        'speed': 'Velocidad',
      }[name] ??
      name;
}

class Pokemon {
  final int id;
  final String name;
  final int height;
  final int weight;
  final int baseExperience;
  final String imageUrl;
  final String shinyUrl;
  final List<String> types;
  final List<Ability> abilities;
  final List<String> moves;
  final List<PokemonStat> stats;

  const Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.imageUrl,
    required this.shinyUrl,
    required this.types,
    required this.abilities,
    required this.moves,
    required this.stats,
  });

  factory Pokemon.fromJson(Map<String, dynamic> j) {
    final sprites = j['sprites'] as Map<String, dynamic>;
    final art = (sprites['other']?['official-artwork'] ?? {}) as Map;
    final front = sprites['front_default'] as String? ?? '';
    final normal = art['front_default'] as String? ?? front;

    return Pokemon(
      id: j['id'] as int,
      name: j['name'] as String,
      height: j['height'] as int,
      weight: j['weight'] as int,
      baseExperience: (j['base_experience'] ?? 0) as int,
      imageUrl: normal,
      shinyUrl: art['front_shiny'] as String? ?? normal,
      types: [for (final t in j['types'] as List) t['type']['name'] as String],
      abilities: [
        for (final a in j['abilities'] as List)
          Ability(a['ability']['name'] as String, a['is_hidden'] == true)
      ],
      moves: [
        for (final m in (j['moves'] as List).take(48))
          m['move']['name'] as String
      ],
      stats: [
        for (final s in j['stats'] as List)
          PokemonStat(s['stat']['name'] as String, s['base_stat'] as int)
      ],
    );
  }

  String get displayName => cap(name);
  String get number => 'N.º ${id.toString().padLeft(4, '0')}';
  int get totalStats => stats.fold(0, (a, s) => a + s.value);
}

class PokemonListItem {
  final int id;
  final String name;
  const PokemonListItem(this.id, this.name);

  factory PokemonListItem.fromJson(Map<String, dynamic> j) =>
      PokemonListItem(idFromUrl(j['url'] as String), j['name'] as String);

  String get displayName => cap(name);
  String get imageUrl => artwork(id);
}

class EvoNode {
  final int id;
  final String name;
  const EvoNode(this.id, this.name);
}

class Species {
  final String description;
  final String genus;
  final String habitat;
  final String generation;
  final int captureRate;
  final int baseHappiness;
  final bool legendary;
  final bool mythical;
  final List<List<EvoNode>> evolution;

  const Species({
    required this.description,
    required this.genus,
    required this.habitat,
    required this.generation,
    required this.captureRate,
    required this.baseHappiness,
    required this.legendary,
    required this.mythical,
    required this.evolution,
  });

  factory Species.fromJson(Map<String, dynamic> j, List<List<EvoNode>> evo) {
    String pick(List list, String key) {
      for (final lang in const ['es', 'en']) {
        for (final e in list) {
          if (e['language']['name'] == lang) {
            return (e[key] as String)
                .replaceAll(RegExp(r'[\n\f\r]+'), ' ')
                .replaceAll('  ', ' ');
          }
        }
      }
      return '';
    }

    return Species(
      description: pick(j['flavor_text_entries'] as List, 'flavor_text'),
      genus: pick(j['genera'] as List, 'genus'),
      habitat: (j['habitat']?['name'] as String?) ?? 'unknown',
      generation: (j['generation']?['name'] as String? ?? '')
          .replaceFirst('generation-', '')
          .toUpperCase(),
      captureRate: (j['capture_rate'] ?? 0) as int,
      baseHappiness: (j['base_happiness'] ?? 0) as int,
      legendary: j['is_legendary'] == true,
      mythical: j['is_mythical'] == true,
      evolution: evo,
    );
  }

  String get habitatName => const {
        'cave': 'Cueva',
        'forest': 'Bosque',
        'grassland': 'Pradera',
        'mountain': 'Montaña',
        'rare': 'Raro',
        'rough-terrain': 'Terreno abrupto',
        'sea': 'Mar',
        'urban': 'Urbano',
        'waters-edge': 'Orilla del agua',
      }[habitat] ??
      'Desconocido';
}

class MoveInfo {
  final String apiName;
  final String name;
  final String type;
  final String damageClass; // physical, special, status
  final int? power;
  final int? accuracy;
  final int? pp;
  final String description;

  const MoveInfo({
    required this.apiName,
    required this.name,
    required this.type,
    required this.damageClass,
    required this.power,
    required this.accuracy,
    required this.pp,
    required this.description,
  });

  factory MoveInfo.fromJson(Map<String, dynamic> j) {
    final api = j['name'] as String;
    var name = pretty(api);
    for (final n in j['names'] as List) {
      if (n['language']['name'] == 'es') {
        name = n['name'] as String;
        break;
      }
    }
    var desc = '';
    final entries = j['flavor_text_entries'] as List;
    for (final lang in const ['es', 'en']) {
      for (final f in entries.reversed) {
        if (f['language']['name'] == lang) {
          desc = (f['flavor_text'] as String).replaceAll(RegExp(r'\s+'), ' ');
          break;
        }
      }
      if (desc.isNotEmpty) break;
    }
    return MoveInfo(
      apiName: api,
      name: name,
      type: j['type']['name'] as String,
      damageClass: (j['damage_class']?['name'] as String?) ?? 'status',
      power: j['power'] as int?,
      accuracy: j['accuracy'] as int?,
      pp: j['pp'] as int?,
      description: desc,
    );
  }

  String get categoryName => const {
        'physical': 'Físico',
        'special': 'Especial',
        'status': 'Estado',
      }[damageClass] ??
      damageClass;
}

class TypeInfo {
  final String name;
  final Set<String> doubleFrom;
  final Set<String> halfFrom;
  final Set<String> zeroFrom;
  const TypeInfo(this.name, this.doubleFrom, this.halfFrom, this.zeroFrom);
}

/// Todo lo de un Pokémon junto (lo que muestra la ficha).
class PokemonDetails {
  final Pokemon pokemon;
  final Species? species;
  final Map<String, TypeInfo> types;
  const PokemonDetails(this.pokemon, this.species, this.types);

  /// Multiplicador de daño que recibe de cada tipo atacante.
  Map<String, double> get effectiveness {
    final out = <String, double>{};
    for (final atk in typeColors.keys) {
      var m = 1.0;
      for (final def in pokemon.types) {
        final info = types[def];
        if (info == null) continue;
        if (info.zeroFrom.contains(atk)) m *= 0;
        if (info.doubleFrom.contains(atk)) m *= 2;
        if (info.halfFrom.contains(atk)) m *= .5;
      }
      out[atk] = m;
    }
    return out;
  }
}

// ============================================================================
//  SERVICIO (peticiones de red con Dio + caché en memoria)
// ============================================================================

class PokeApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://pokeapi.co/api/v2/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  static final Map<int, Future<Pokemon>> _pokemon = {};
  static final Map<int, Future<Species>> _species = {};
  static final Map<int, Future<PokemonDetails>> _details = {};
  static final Map<String, Future<MoveInfo>> _moves = {};
  static Future<List<PokemonListItem>>? _list;
  static Future<Map<String, TypeInfo>>? _types;

  /// Tipos de cada Pokémon (llenado con 18 peticiones en vez de 151).
  static final Map<int, List<String>> typesById = {};

  /// Guarda el Future en caché; si falla, lo borra para poder reintentar.
  static Future<T> _memo<K, T>(
      Map<K, Future<T>> cache, K key, Future<T> Function() load) {
    return cache.putIfAbsent(key, () {
      return load().catchError((Object e) {
        cache.remove(key);
        throw e;
      });
    });
  }

  /// GET /pokemon?limit=151
  static Future<List<PokemonListItem>> list(int limit) {
    return _list ??= () async {
      try {
        final res =
            await _dio.get('pokemon', queryParameters: {'limit': limit});
        return [
          for (final e in res.data['results'] as List)
            PokemonListItem.fromJson(e as Map<String, dynamic>)
        ];
      } catch (e) {
        _list = null;
        rethrow;
      }
    }();
  }

  /// GET /type/{nombre} × 18 → tipos de todos los Pokémon + debilidades.
  static Future<Map<String, TypeInfo>> types() {
    return _types ??= () async {
      final names = typeColors.keys.toList();
      final responses = await Future.wait(names.map((n) => _dio
          .get('type/$n')
          .then<Response<dynamic>?>((r) => r)
          .catchError((Object _) => null)));

      final result = <String, TypeInfo>{};
      final slots = <int, Map<int, String>>{};

      for (var i = 0; i < names.length; i++) {
        final res = responses[i];
        if (res == null) continue;
        final data = res.data as Map<String, dynamic>;
        final dr = data['damage_relations'] as Map<String, dynamic>;
        Set<String> rel(String k) =>
            {for (final t in dr[k] as List) t['name'] as String};

        result[names[i]] = TypeInfo(
          names[i],
          rel('double_damage_from'),
          rel('half_damage_from'),
          rel('no_damage_from'),
        );
        for (final e in data['pokemon'] as List) {
          final id = idFromUrl(e['pokemon']['url'] as String);
          (slots[id] ??= {})[e['slot'] as int] = names[i];
        }
      }

      slots.forEach((id, m) {
        final keys = m.keys.toList()..sort();
        typesById[id] = [for (final k in keys) m[k]!];
      });

      if (result.isEmpty) _types = null;
      return result;
    }();
  }

  /// GET /pokemon/{id}/
  static Future<Pokemon> pokemon(int id) => _memo(_pokemon, id, () async {
        final res = await _dio.get('pokemon/$id/');
        return Pokemon.fromJson(res.data as Map<String, dynamic>);
      });

  /// GET /pokemon-species/{id}/ + cadena evolutiva
  static Future<Species> species(int id) => _memo(_species, id, () async {
        final res = await _dio.get('pokemon-species/$id/');
        final data = res.data as Map<String, dynamic>;
        var evo = <List<EvoNode>>[];
        final evoUrl = data['evolution_chain']?['url'] as String?;
        if (evoUrl != null) {
          try {
            final chain = await _dio.get(evoUrl);
            evo = _parseChain(chain.data['chain'] as Map<String, dynamic>);
          } catch (_) {}
        }
        return Species.fromJson(data, evo);
      });

  static List<List<EvoNode>> _parseChain(Map<String, dynamic> root) {
    final stages = <List<EvoNode>>[];
    var level = <Map<String, dynamic>>[root];
    while (level.isNotEmpty) {
      stages.add([
        for (final n in level)
          EvoNode(idFromUrl(n['species']['url'] as String),
              n['species']['name'] as String)
      ]);
      level = [
        for (final n in level)
          for (final c in n['evolves_to'] as List) c as Map<String, dynamic>
      ];
    }
    return stages;
  }

  /// GET /move/{nombre}/
  static Future<MoveInfo> move(String name) => _memo(_moves, name, () async {
        final res = await _dio.get('move/$name/');
        return MoveInfo.fromJson(res.data as Map<String, dynamic>);
      });

  static Future<Species?> _safeSpecies(int id) async {
    try {
      return await species(id);
    } catch (_) {
      return null;
    }
  }

  /// Todo junto, en paralelo.
  static Future<PokemonDetails> details(int id) =>
      _memo(_details, id, () async {
        final p = pokemon(id);
        final s = _safeSpecies(id);
        final t = types();
        return PokemonDetails(await p, await s, await t);
      });

  /// Precarga datos + imagen para que se vea al instante.
  static void prefetch(BuildContext context, int id) {
    if (id < 1 || id > 1025) return;
    details(id).then((d) {
      if (context.mounted) {
        precacheImage(NetworkImage(d.pokemon.imageUrl), context,
            onError: (_, __) {});
      }
    }, onError: (_) {});
  }
}

// ============================================================================
//  TIPOS: colores, nombres e íconos
// ============================================================================

const Map<String, Color> typeColors = {
  'normal': Color(0xFFA8A77A),
  'fire': Color(0xFFEE8130),
  'water': Color(0xFF6390F0),
  'electric': Color(0xFFF2C21B),
  'grass': Color(0xFF6DBE45),
  'ice': Color(0xFF5CC9C4),
  'fighting': Color(0xFFC22E28),
  'poison': Color(0xFFA33EA1),
  'ground': Color(0xFFD4A63F),
  'flying': Color(0xFF8F7BE0),
  'psychic': Color(0xFFF95587),
  'bug': Color(0xFF9BB01A),
  'rock': Color(0xFFB6A136),
  'ghost': Color(0xFF735797),
  'dragon': Color(0xFF6F35FC),
  'dark': Color(0xFF705746),
  'steel': Color(0xFF8F8FB0),
  'fairy': Color(0xFFD685AD),
};

const Map<String, String> _typeNames = {
  'normal': 'Normal',
  'fire': 'Fuego',
  'water': 'Agua',
  'electric': 'Eléctrico',
  'grass': 'Planta',
  'ice': 'Hielo',
  'fighting': 'Lucha',
  'poison': 'Veneno',
  'ground': 'Tierra',
  'flying': 'Volador',
  'psychic': 'Psíquico',
  'bug': 'Bicho',
  'rock': 'Roca',
  'ghost': 'Fantasma',
  'dragon': 'Dragón',
  'dark': 'Siniestro',
  'steel': 'Acero',
  'fairy': 'Hada',
};

const Map<String, IconData> _typeIcons = {
  'normal': Icons.circle_outlined,
  'fire': Icons.local_fire_department,
  'water': Icons.water_drop,
  'electric': Icons.bolt,
  'grass': Icons.eco,
  'ice': Icons.ac_unit,
  'fighting': Icons.sports_mma,
  'poison': Icons.science,
  'ground': Icons.terrain,
  'flying': Icons.air,
  'psychic': Icons.psychology,
  'bug': Icons.bug_report,
  'rock': Icons.landscape,
  'ghost': Icons.nights_stay,
  'dragon': Icons.whatshot,
  'dark': Icons.dark_mode,
  'steel': Icons.shield,
  'fairy': Icons.auto_awesome,
};

Color typeColor(String t) => typeColors[t] ?? Colors.grey;
String typeName(String t) => _typeNames[t] ?? cap(t);
IconData typeIcon(String t) => _typeIcons[t] ?? Icons.circle;

Color darken(Color c, [double amount = .18]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
}

Color lighten(Color c, [double amount = .1]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
}

Color readable(Color c) => c.computeLuminance() > .42 ? darken(c, .3) : c;

// ============================================================================
//  NAVEGACIÓN → abre la ficha con la animación de la Poké Ball
// ============================================================================

void openPokemon(BuildContext context, int id) {
  PokeApi.details(id); // empieza a descargar mientras rebota la Poké Ball
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => DetailPage(id: id),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

// ============================================================================
//  PANTALLA PRINCIPAL
// ============================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Un solo controlador para TODAS las animaciones en bucle del home.
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();
  final ScrollController _scroll = ScrollController();

  late Future<List<Object>> _data = _load();
  final int _featured = math.Random().nextInt(kMaxPokemon) + 1;
  String _query = '';
  String? _type;
  int _region = 0;
  Timer? _debounce;

  // OPTIMIZACIÓN: el filtrado se memoriza; solo se recalcula si cambia algo
  List<PokemonListItem>? _filtered;
  String? _filterKey;

  Future<List<Object>> _load() =>
      Future.wait<Object>([PokeApi.list(kMaxPokemon), PokeApi.types()]);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  // OPTIMIZACIÓN: pausa las animaciones del header cuando ya no se ven
  void _onScroll() {
    final visible = _scroll.offset < 700;
    if (visible && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!visible && _loop.isAnimating) {
      _loop.stop();
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _query = v.trim().toLowerCase());
    });
  }

  List<PokemonListItem> _apply(List<PokemonListItem> all) {
    final key = '$_query|$_type|$_region|${all.length}';
    final cached = _filtered;
    if (cached != null && key == _filterKey) return cached;
    final r = kRegions[_region];
    _filterKey = key;
    return _filtered = [
      for (final p in all)
        if (p.id >= r.from &&
            p.id <= r.to &&
            (_query.isEmpty ||
                p.name.contains(_query) ||
                p.id.toString() == _query) &&
            (_type == null ||
                (PokeApi.typesById[p.id]?.contains(_type) ?? false)))
          p
    ];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _loop.dispose();
    super.dispose();
  }

  String get _title {
    if (_type != null) return 'Tipo ${typeName(_type!)}';
    if (_region == 0) return 'Todos los Pokémon';
    return 'Región de ${kRegions[_region].name}';
  }

  @override
  Widget build(BuildContext context) {
    final showFeatured = _query.isEmpty && _type == null && _region == 0;

    return Scaffold(
      floatingActionButton: _RandomButton(
        onTap: () =>
            openPokemon(context, math.Random().nextInt(kMaxPokemon) + 1),
      ),
      body: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 370,
            toolbarHeight: 64,
            backgroundColor: kNavy,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 20,
            title: const _Logo(height: 42),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: _HeaderBadge(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: _Header(loop: _loop),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: _SearchField(onChanged: _onSearch),
                  ),
                ),
              ),
            ),
          ),
          // Barra de filtros fija (se queda arriba al hacer scroll)
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBarDelegate(
              _FilterBar(
                region: _region,
                type: _type,
                onRegion: (i) => setState(() => _region = i),
                onType: (t) => setState(() => _type = t),
                onClear: () => setState(() {
                  _region = 0;
                  _type = null;
                }),
              ),
            ),
          ),
          if (showFeatured)
            SliverToBoxAdapter(
              child: _FeaturedBanner(id: _featured, loop: _loop),
            ),
          FutureBuilder<List<Object>>(
            future: _data,
            builder: (context, snap) {
              if (snap.hasError) {
                return SliverToBoxAdapter(
                  child: _ErrorBox(
                    onRetry: () => setState(() => _data = _load()),
                  ),
                );
              }
              if (!snap.hasData) {
                return const SliverToBoxAdapter(child: _GridLoading());
              }

              final items = _apply(snap.data![0] as List<PokemonListItem>);
              final color = _type == null ? kRed : typeColor(_type!);

              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: _title,
                      count: items.length,
                      color: color,
                    ),
                  ),
                  if (items.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyBox())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.08,
                        ),
                        // Solo se construyen las tarjetas visibles
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _PokemonCard(
                            key: ValueKey(items[i].id),
                            item: items[i],
                            index: i,
                          ),
                          childCount: items.length,
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: false, // ya tiene la suya
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SliverToBoxAdapter(child: _Footer()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Logo
class _Logo extends StatelessWidget {
  final double height;
  const _Logo({this.height = 40});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      kLogoUrl,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Text(
        'POKÉMON',
        style: TextStyle(
          color: Colors.white,
          fontSize: height * .55,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PokeBall(size: 16),
          SizedBox(width: 8),
          Text(
            '1025 Pokémon',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Header
class _Header extends StatelessWidget {
  final Animation<double> loop;
  const _Header({required this.loop});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // fondo azul marino profesional
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF07142E), kNavy, kNavy2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // luces suaves (azul y rojo)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(.75, -.4),
              radius: .9,
              colors: [Color(0x552A75BB), Color(0x002A75BB)],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-.9, .9),
              radius: .8,
              colors: [Color(0x33E3350D), Color(0x00E3350D)],
            ),
          ),
        ),
        // destellos
        RepaintBoundary(
          child: CustomPaint(painter: _ParticlesPainter(loop)),
        ),
        // Poké Ball de marca de agua
        Positioned(
          left: -90,
          bottom: -120,
          child: RotationTransition(
            turns: loop,
            child: RepaintBoundary(
              child: PokeBallOutline(
                size: 340,
                color: Colors.white.withValues(alpha: .04),
              ),
            ),
          ),
        ),
        // Poké Ball 3D + Pikachu
        Positioned(
          right: -30,
          top: 40,
          child: _FloatingBall(loop: loop, size: 170),
        ),
        Positioned(
          right: 36,
          bottom: 100,
          child: _Appear(
            delay: 350,
            offsetY: 60,
            child: _WavingPikachu(loop: loop),
          ),
        ),
        // texto
        Positioned(
          left: 24,
          right: 240,
          bottom: 116,
          child: _Appear(
            delay: 150,
            offsetY: 30,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kYellow.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kYellow.withValues(alpha: .4)),
                    ),
                    child: const Text(
                      'POKÉDEX NACIONAL',
                      style: TextStyle(
                        color: kYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: -.5,
                      ),
                      children: [
                        TextSpan(text: 'Encuentra a tu\nPokémon '),
                        TextSpan(
                          text: 'favorito',
                          style: TextStyle(color: kYellow),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Datos en vivo de los 1025 Pokémon de todas las regiones',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .7),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pikachu (imagen oficial HD de la PokeAPI): brinca, se mece, saluda con
/// la manita y dice "¡Pika pika!" en ciclos. Todo con un solo controlador.
class _WavingPikachu extends StatelessWidget {
  final Animation<double> loop;
  const _WavingPikachu({required this.loop});

  static const double _sayStart = .06;
  static const double _sayEnd = .5;

  static double _talk(double v) {
    if (v < _sayStart || v > _sayEnd) return 0;
    return (v - _sayStart) / (_sayEnd - _sayStart);
  }


  @override
  Widget build(BuildContext context) {
    // Si existe assets/pikachu_saludo.gif se usa ese (tu animación);
    // si no, la imagen oficial HD de la PokeAPI.
    final pikachu = RepaintBoundary(
      child: Image.asset(
        kPikachuAsset,
        height: 160,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Image.network(
          artwork(25),
          height: 152,
          cacheWidth: 320,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        ),
      ),
    );

    return SizedBox(
      width: 180,
      height: 175,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // sombra
          Positioned(
            left: 45,
            right: 45,
            bottom: 0,
            height: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withValues(alpha: .22),
              ),
            ),
          ),
          // Pikachu
          Positioned(
            bottom: 6,
            child: AnimatedBuilder(
              animation: loop,
              child: pikachu,
              builder: (_, c) {
                final breathe = math.sin(loop.value * 2 * math.pi * 3) * .012;
                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(1 - breathe * .5, 1 + breathe, 1),
                  child: c,
                );
              },
            ),
          ),
          // globo "¡Pika pika!"
          Positioned(
            right: -8,
            top: -14,
            child: AnimatedBuilder(
              animation: loop,
              builder: (_, c) {
                final k = _talk(loop.value);
                final pop = k == 0
                    ? 0.0
                    : Curves.elasticOut.transform((k * 4).clamp(0.0, 1.0)) *
                        (1 - ((k - .88) * 9).clamp(0.0, 1.0));
                return Transform.scale(
                  alignment: Alignment.bottomLeft,
                  scale: pop,
                  child: c,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFF2C21B), size: 16),
                    SizedBox(width: 2),
                    Text(
                      '¡Pika pika!',
                      style: TextStyle(
                        color: kRed,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBall extends StatelessWidget {
  final Animation<double> loop;
  final double size;
  const _FloatingBall({required this.loop, required this.size});

  @override
  Widget build(BuildContext context) {
    // La Poké Ball se pinta UNA vez; solo se mueve/rota (muy barato).
    final ball = RepaintBoundary(child: PokeBall(size: size));
    return SizedBox(
      width: size + 60,
      height: size + 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // halo de luz
          Container(
            width: size + 60,
            height: size + 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: .45),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: loop,
            child: ball,
            builder: (_, child) {
              final t = loop.value * 2 * math.pi;
              return Transform.translate(
                offset: Offset(0, math.sin(t * 2) * 10),
                child: Transform.rotate(
                  angle: math.sin(t) * .22,
                  child: child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      padding: const EdgeInsets.only(left: 18, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? kYellow : Colors.transparent,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x44000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              color: focused ? kNavy : const Color(0xFF8A90A2)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: (v) {
                widget.onChanged(v);
                setState(() {});
              },
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
              cursorColor: kRed,
              decoration: const InputDecoration(
                hintText: 'Buscar Pokémon por nombre o número',
                hintStyle: TextStyle(
                    color: Color(0xFF9AA0B1), fontWeight: FontWeight.w500),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _ctrl.text.isEmpty
                ? Container(
                    key: const ValueKey('hint'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ej. pikachu · 25',
                      style: TextStyle(
                        color: Color(0xFF8A90A2),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('clear'),
                    tooltip: 'Borrar',
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF8A90A2)),
                    onPressed: () {
                      _ctrl.clear();
                      widget.onChanged('');
                      setState(() {});
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Filtros
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _FilterBarDelegate(this.child);

  @override
  double get minExtent => 76;
  @override
  double get maxExtent => 76;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: overlaps ? Colors.white : kBg,
        boxShadow: overlaps
            ? const [
                BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4)),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate old) => old.child != child;
}

class _FilterBar extends StatelessWidget {
  final int region;
  final String? type;
  final ValueChanged<int> onRegion;
  final ValueChanged<String?> onType;
  final VoidCallback onClear;
  const _FilterBar({
    required this.region,
    required this.type,
    required this.onRegion,
    required this.onType,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final active = region != 0 || type != null;
    final r = kRegions[region];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, size: 20, color: Color(0xFF5A6072)),
          const SizedBox(width: 8),
          const Text(
            'Filtrar',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF3A3D4A),
            ),
          ),
          const SizedBox(width: 16),
          // ---------- Región
          _Dropdown<int>(
            label: 'Región',
            value: region == 0 ? 'Todas' : r.name,
            leading: const _DotIcon(color: kBlue, icon: Icons.public_rounded),
            accent: kBlue,
            active: region != 0,
            selected: region,
            onSelected: onRegion,
            items: [
              for (var i = 0; i < kRegions.length; i++)
                _DropItem(
                  value: i,
                  label: i == 0 ? 'Todas las regiones' : kRegions[i].name,
                  detail: i == 0
                      ? 'N.º 1 – 1025'
                      : 'N.º ${kRegions[i].from} – ${kRegions[i].to}',
                  leading: _DotIcon(
                    color: i == 0 ? kNavy : kBlue,
                    icon: i == 0 ? Icons.language_rounded : Icons.place_rounded,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          // ---------- Tipo
          _Dropdown<String?>(
            label: 'Tipo',
            value: type == null ? 'Todos' : typeName(type!),
            leading: type == null
                ? const _DotIcon(color: kNavy, icon: Icons.category_rounded)
                : _DotIcon(color: typeColor(type!), icon: typeIcon(type!)),
            accent: type == null ? kNavy : typeColor(type!),
            active: type != null,
            selected: type,
            onSelected: onType,
            items: [
              const _DropItem<String?>(
                value: null,
                label: 'Todos los tipos',
                leading: _DotIcon(color: kNavy, icon: Icons.category_rounded),
              ),
              for (final t in typeColors.keys)
                _DropItem<String?>(
                  value: t,
                  label: typeName(t),
                  leading: _DotIcon(color: typeColor(t), icon: typeIcon(t)),
                ),
            ],
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: active
                ? TextButton.icon(
                    key: const ValueKey('clear'),
                    onPressed: onClear,
                    style: TextButton.styleFrom(foregroundColor: kRed),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text(
                      'Limpiar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        ],
      ),
    );
  }
}

class _DropItem<T> {
  final T value;
  final String label;
  final String? detail;
  final Widget? leading;
  const _DropItem({
    required this.value,
    required this.label,
    this.detail,
    this.leading,
  });
}

/// Ícono dentro de un círculo de color (tipos, regiones).
class _DotIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _DotIcon({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 15, color: Colors.white),
    );
  }
}

/// Desplegable limpio con menú flotante.
class _Dropdown<T> extends StatelessWidget {
  final String label;
  final String value;
  final Widget leading;
  final Color accent;
  final bool active;
  final T selected;
  final ValueChanged<T> onSelected;
  final List<_DropItem<T>> items;

  const _Dropdown({
    super.key,
    required this.label,
    required this.value,
    required this.leading,
    required this.accent,
    required this.active,
    required this.selected,
    required this.onSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(10),
        shadowColor: const WidgetStatePropertyAll(Color(0x55000000)),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 8)),
        maximumSize: const WidgetStatePropertyAll(Size(320, 440)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      menuChildren: [
        for (final it in items)
          MenuItemButton(
            onPressed: () => onSelected(it.value),
            leadingIcon: it.leading,
            trailingIcon: it.value == selected
                ? Icon(Icons.check_rounded, size: 18, color: accent)
                : null,
            style: MenuItemButton.styleFrom(
              minimumSize: const Size(260, 46),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: it.value == selected
                  ? accent.withValues(alpha: .08)
                  : Colors.transparent,
            ),
            child: Text.rich(
              TextSpan(
                text: it.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1F2B),
                  fontSize: 14,
                ),
                children: [
                  if (it.detail != null)
                    TextSpan(
                      text: '   ${it.detail}',
                      style: const TextStyle(
                        color: Color(0xFF9AA0B1),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
      builder: (context, controller, _) {
        final open = controller.isOpen;
        return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: active || open ? accent : const Color(0xFFE1E3EA),
              width: active || open ? 1.6 : 1,
            ),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onTap: () => open ? controller.close() : controller.open(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading,
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .9,
                          color: Color(0xFF9AA0B1),
                        ),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D1F2B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: open ? .5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF5A6072)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader(
      {required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1D1F2B),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count Pokémon',
              style: TextStyle(
                  color: readable(color), fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Destacado
class _FeaturedBanner extends StatelessWidget {
  final int id;
  final Animation<double> loop;
  const _FeaturedBanner({required this.id, required this.loop});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pokemon>(
      future: PokeApi.pokemon(id),
      builder: (context, snap) {
        final p = snap.data;
        final color =
            p == null ? const Color(0xFFB9BCC8) : typeColor(p.types.first);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lighten(color, .06), darken(color, .2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .4),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: p == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () => openPokemon(context, p.id),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -40,
                              bottom: -56,
                              child: RotationTransition(
                                turns: loop,
                                child: RepaintBoundary(
                                  child: PokeBallOutline(
                                    size: 250,
                                    color: Colors.white.withValues(alpha: .2),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const _Pill('★ DESTACADO DEL DÍA'),
                                        const SizedBox(height: 8),
                                        Text(
                                          p.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Text(
                                          p.number,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            for (final t in p.types)
                                              TypeChip(type: t, onColor: true),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  _Floating(
                                    loop: loop,
                                    amount: 12,
                                    child: Image.network(
                                      p.imageUrl,
                                      height: 165,
                                      cacheWidth: 330,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- Tarjeta
class _PokemonCard extends StatefulWidget {
  final PokemonListItem item;
  final int index;
  const _PokemonCard({super.key, required this.item, required this.index});

  @override
  State<_PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<_PokemonCard> {
  bool _hover = false;

  void _setHover(bool v) {
    if (_hover == v) return;
    setState(() => _hover = v);
    if (v) PokeApi.prefetch(context, widget.item.id); // abre al instante
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final types = PokeApi.typesById[item.id] ?? const <String>[];
    final color =
        types.isEmpty ? const Color(0xFFB0B4C0) : typeColor(types.first);

    final staticImg = Image.network(
      item.imageUrl,
      fit: BoxFit.contain,
      cacheWidth: 256, // decodifica pequeño → menos memoria
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      frameBuilder: (_, child, frame, sync) => sync
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 400),
              child: child,
            ),
      errorBuilder: (_, __, ___) => const Icon(
        Icons.catching_pokemon,
        color: Colors.white54,
        size: 50,
      ),
    );

    // Al pasar el cursor: animación característica según su tipo (en HD)
    final image = _HoverPokemon(
      active: _hover,
      type: types.isEmpty ? 'normal' : types.first,
      child: staticImg,
    );

    Widget card = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: () {
          _setHover(false);
          openPokemon(context, item.id);
        },
        child: AnimatedScale(
          scale: _hover ? 1.05 : 1,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lighten(color, .05), darken(color, .15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: LayoutBuilder(
                builder: (context, box) {
                  final img = box.maxHeight * .64;
                  return Stack(
                    children: [
                      Positioned(
                        right: 10,
                        top: 6,
                        child: Text(
                          '#${item.id.toString().padLeft(4, '0')}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .22),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -26,
                        bottom: -26,
                        child: AnimatedRotation(
                          turns: _hover ? .5 : 0,
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutBack,
                          child: PokeBallOutline(
                            size: img + 36,
                            color: Colors.white.withValues(alpha: .24),
                          ),
                        ),
                      ),
                      // brillo detrás del Pokémon al hacer hover
                      Positioned(
                        right: 6,
                        bottom: 6,
                        width: img,
                        height: img,
                        child: AnimatedOpacity(
                          opacity: _hover ? 1 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                Colors.white.withValues(alpha: .55),
                                Colors.white.withValues(alpha: 0),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        width: img,
                        height: img,
                        child: AnimatedSlide(
                          offset: _hover ? const Offset(0, -.05) : Offset.zero,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          child: AnimatedScale(
                            scale: _hover ? 1.12 : 1,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutBack,
                            child: image,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 14,
                        right: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                shadows: [
                                  Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(1, 2)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final t in types)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: TypeChip(
                                    type: t, onColor: true, small: true),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Entrada escalonada solo para las primeras (las demás aparecen directo)
    if (widget.index < 16) {
      card = _Appear(delay: widget.index * 45, offsetY: 36, child: card);
    }
    return RepaintBoundary(child: card);
  }
}

class _RandomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RandomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: kNavy,
      foregroundColor: Colors.white,
      onPressed: onTap,
      icon: const PokeBall(size: 26),
      label: const Text(
        '¡Sorpréndeme!',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

// ============================================================================
//  FICHA DEL POKÉMON + ANIMACIÓN DE LA POKÉ BALL
// ============================================================================

// Línea de tiempo de la intro (0 → 1)
// Línea de tiempo de la intro (0 → 1), duración total 4.2 s
const double _kBounceEnd = .26; // cae y rebota            (~1.1 s)
const double _kShakeEnd = .48; // se agita 3 veces         (~0.9 s)
const double _kOpenStart = .50; // toma impulso y SE ABRE
const double _kOpenEnd = .62; // ya abierta               (~0.5 s)
//                                se queda abierta brillando (~0.35 s)
const double _kFlashStart = .70; // DESPUÉS: destello
const double _kFlashEnd = .86; // termina el destello
const double _kBallFadeStart = .73; // la bola se va bajo el blanco
const double _kBallFadeEnd = .75;
const double _kMount = .725; // la ficha se construye bajo el blanco
const double _kRevealStart = .74;
const double _kRevealEnd = .76;
const double _kEmergeStart = .86; // ya que se fue el destello → sale el Pokémon

class DetailPage extends StatefulWidget {
  final int id;
  const DetailPage({super.key, required this.id});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with TickerProviderStateMixin {
  late int _id = widget.id;
  late Future<PokemonDetails> _future = PokeApi.details(_id);
  bool _shiny = false;
  bool _mountContent = false;
  bool _introDone = false;
  Color _introColor = kRed;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
    // aunque Windows tenga "reducir animaciones", la intro dura lo mismo
    animationBehavior: AnimationBehavior.preserve,
  );
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat();

  late final Animation<double> _revealFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(_kRevealStart, _kRevealEnd),
  );
  // El Pokémon sale de la Poké Ball cuando termina el destello
  late final Animation<double> _emerge = Tween(begin: .05, end: 1.0)
      .animate(CurvedAnimation(
    parent: _intro,
    curve: const Interval(_kEmergeStart, .98, curve: Curves.easeOutBack),
  ));
  late final Animation<double> _emergeFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(_kEmergeStart, .88),
  );
  // La hoja de información sube después
  late final Animation<Offset> _sheetIn =
      Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
    CurvedAnimation(
      parent: _intro,
      curve: const Interval(.87, 1, curve: Curves.easeOutCubic),
    ),
  );

  @override
  void initState() {
    super.initState();
    _intro.addListener(() {
      if (!_mountContent && _intro.value >= _kMount) {
        setState(() => _mountContent = true);
      }
    });
    _intro.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _introDone = true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _runIntro());
  }

  Future<void> _runIntro() async {
    var ready = false;
    _future.then((d) async {
      if (mounted) {
        _introColor = typeColor(d.pokemon.types.first);
        await precacheImage(NetworkImage(d.pokemon.imageUrl), context,
                onError: (_, __) {})
            .timeout(const Duration(seconds: 4), onTimeout: () {});
      }
    }).catchError((Object _) {}).whenComplete(() => ready = true);

    // 1) cae y rebota  2) se agita
    await _intro.animateTo(_kShakeEnd);
    // Si la API aún no responde, se sigue agitando
    while (!ready && mounted) {
      _intro.value = _kBounceEnd;
      await _intro.animateTo(_kShakeEnd);
    }
    if (!mounted) return;
    // 3) se abre  4) destello  5) aparece la ficha
    _intro.forward();
    PokeApi.prefetch(context, _id + 1);
    PokeApi.prefetch(context, _id - 1);
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _goTo(int id) {
    if (id < 1 || id > 1025 || id == _id) return;
    setState(() {
      _id = id;
      _shiny = false;
      _future = PokeApi.details(id);
    });
    PokeApi.prefetch(context, id + 1);
    PokeApi.prefetch(context, id - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kInk,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_mountContent)
            FadeTransition(
              opacity: _revealFade,
              child: RepaintBoundary(
                child: FutureBuilder<PokemonDetails>(
                  future: _future,
                  builder: (context, snap) {
                    final d = snap.data;
                    if (d == null) {
                      if (snap.hasError) {
                        return _ErrorPage(
                          onRetry: () => setState(
                              () => _future = PokeApi.details(_id)),
                        );
                      }
                      return const ColoredBox(
                        color: kRed,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                    final loading =
                        snap.connectionState != ConnectionState.done;
                    return _buildDetail(d, loading);
                  },
                ),
              ),
            ),
          if (!_introDone)
            Positioned.fill(
              child: RepaintBoundary(
                child: _PokeBallIntro(anim: _intro, color: _introColor),
              ),
            ),
          if (!_introDone)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  color: Colors.white70,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetail(PokemonDetails d, bool loading) {
    final p = d.pokemon;
    final s = d.species;
    final color = typeColor(p.types.first);
    final accent = readable(color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lighten(color, .04), darken(color, .25)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // destellos de fondo (se pintan sin reconstruir widgets)
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _ParticlesPainter(_loop)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
          children: [
            // ----- Barra superior
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: const Center(child: _Logo(height: 30)),
                  ),
                  IconButton(
                    tooltip: 'Versión variocolor',
                    color: Colors.white,
                    onPressed: () => setState(() => _shiny = !_shiny),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (c, a) =>
                          RotationTransition(turns: a, child: c),
                      child: Icon(
                        _shiny
                            ? Icons.auto_awesome
                            : Icons.auto_awesome_outlined,
                        key: ValueKey(_shiny),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ----- Nombre, número, categoría y tipos
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position:
                        Tween(begin: const Offset(.12, 0), end: Offset.zero)
                            .animate(a),
                    child: child,
                  ),
                ),
                child: Row(
                  key: ValueKey(p.id),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (s != null && (s.legendary || s.mythical))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _Pill(
                                  s.mythical ? '✦ SINGULAR' : '♛ LEGENDARIO'),
                            ),
                          Text(
                            p.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              shadows: [
                                Shadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(2, 3)),
                              ],
                            ),
                          ),
                          if (s != null && s.genus.isNotEmpty)
                            Text(
                              s.genus,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final t in p.types)
                                TypeChip(type: t, onColor: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      p.number,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ----- Imagen flotante con halo
            SizedBox(
              height: 250,
              width: 560,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Colors.white.withValues(alpha: .5),
                        Colors.white.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                  RotationTransition(
                    turns: _loop,
                    child: RepaintBoundary(
                      child: PokeBallOutline(
                        size: 230,
                        color: Colors.white.withValues(alpha: .22),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                          painter: _EmergeRingPainter(_intro)),
                    ),
                  ),
                  FadeTransition(
                    opacity: _emergeFade,
                    child: ScaleTransition(
                    scale: _emerge,
                    child: _Floating(
                    loop: _loop,
                    amount: 14,
                    speed: 3,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, a) => ScaleTransition(
                        scale:
                            CurvedAnimation(parent: a, curve: Curves.easeOutBack),
                        child: FadeTransition(opacity: a, child: child),
                      ),
                      child: Image.network(
                        _shiny ? p.shinyUrl : p.imageUrl,
                        key: ValueKey('${p.id}-$_shiny'),
                        height: 215,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  ),
                  ),
                  Positioned(
                    left: 12,
                    child: _NavButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: p.id > 1 ? () => _goTo(p.id - 1) : null,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    child: _NavButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _goTo(p.id + 1),
                    ),
                  ),
                  if (loading)
                    const Positioned(
                      bottom: 4,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            // ----- Hoja blanca con pestañas
            Expanded(
              child: SlideTransition(
                position: _sheetIn,
                child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: DefaultTabController(
                  length: 5,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: accent,
                        unselectedLabelColor: Colors.black45,
                        indicatorColor: accent,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15),
                        tabs: const [
                          Tab(text: 'Información'),
                          Tab(text: 'Estadísticas'),
                          Tab(text: 'Evolución'),
                          Tab(text: 'Debilidades'),
                          Tab(text: 'Movimientos'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _InfoTab(d: d, color: color, accent: accent),
                            _StatsTab(p: p, color: color, accent: accent),
                            _EvolutionTab(
                              d: d,
                              color: color,
                              accent: accent,
                              onSelect: _goTo,
                            ),
                            _WeakTab(d: d, accent: accent),
                            _MovesTab(p: p, color: color, accent: accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ],
        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Intro
/// Poké Ball "3D": cae rodando, rebota, se agita 3 veces, toma impulso,
/// se abre la tapa en perspectiva, sale luz, destello blanco y listo.
class _PokeBallIntro extends StatelessWidget {
  final Animation<double> anim;
  final Color color;
  const _PokeBallIntro({required this.anim, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      final size = (math.min(w, h) * .3).clamp(110.0, 180.0);
      final cx = w / 2;
      final floorY = h * .56 + size * .5;

      return AnimatedBuilder(
        animation: anim,
        builder: (context, _) {
          final v = anim.value;
          double seg(double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);

          // --- 1. Cae rodando y rebota
          final fall = seg(0, _kBounceEnd);
          final drop = Curves.bounceOut.transform(fall);
          final lift = 1 - drop; // 0 = en el piso
          final dy = -(h * .56 + size) * lift;
          final roll = (1 - Curves.easeOutCubic.transform(fall)) * -5 * math.pi;
          final squash =
              fall < 1 ? (1 - (lift * 10).clamp(0.0, 1.0)) * .16 : 0.0;

          // --- 2. Se agita 3 veces (con pausas, como en el juego)
          final shake = seg(_kBounceEnd, _kShakeEnd);
          var wobble = 0.0;
          var glow = 0.0;
          if (shake > 0 && shake < 1) {
            final local = (shake * 3) % 1;
            if (local < .6) {
              final k = local / .6;
              wobble = math.sin(k * 2 * math.pi) * .38;
              glow = math.sin(k * math.pi);
            }
          }

          // --- 3. Impulso + apertura en perspectiva
          final charge = seg(_kShakeEnd, _kOpenStart);
          if (v >= _kShakeEnd) glow = 1;
          final open = Curves.easeOutBack.transform(seg(_kOpenStart, _kOpenEnd));
          final jitter = charge > 0 && charge < 1
              ? math.sin(charge * 60) * .025
              : 0.0;
          final pop = 1 + charge * .12 + jitter;

          // --- 4. Destello  5. La bola se desvanece bajo el blanco
          final flash = seg(_kFlashStart, _kFlashEnd);
          final fade = seg(_kBallFadeStart, _kBallFadeEnd);
          final bgFade = seg(_kRevealStart, _kRevealEnd);

          final ballCenter = Offset(cx, floorY - size / 2);
          final shadowW = size * (.95 - .55 * lift) * (1 - fade);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Fondo oscuro con foco de luz del color del Pokémon
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, .15),
                    radius: 1.1,
                    colors: [
                      Color.lerp(kInk, color, .5)!
                          .withValues(alpha: 1 - bgFade),
                      kInk.withValues(alpha: 1 - bgFade),
                    ],
                  ),
                ),
              ),
              // Sombra en el piso
              Positioned(
                left: cx - shadowW / 2,
                top: floorY - 8,
                width: shadowW,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withValues(
                        alpha: (.5 * (1 - lift * .7)) * (1 - fade)),
                  ),
                ),
              ),
              // La Poké Ball
              Positioned(
                left: cx - size / 2,
                top: floorY - size + dy,
                width: size,
                height: size,
                child: Opacity(
                  opacity: 1 - fade,
                  child: Transform.scale(
                    scale: pop + fade * .3,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(
                          1 + squash * .6, 1 - squash, 1),
                      child: Transform.rotate(
                        alignment: Alignment.bottomCenter,
                        angle: wobble,
                        child: CustomPaint(
                          painter: PokeBallPainter(
                            open: open,
                            glow: glow,
                            spin: roll + wobble * .9,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Destello
              IgnorePointer(
                child: CustomPaint(
                  painter: _FlashPainter(
                    t: flash,
                    color: color,
                    center: ballCenter,
                  ),
                ),
              ),
              // Texto
              Positioned(
                left: 0,
                right: 0,
                top: floorY + 34,
                child: Opacity(
                  opacity:
                      (seg(.2, _kBounceEnd) * (1 - seg(_kShakeEnd, _kOpenStart)))
                          .clamp(0.0, 1.0),
                  child: Text(
                    v < _kBounceEnd + .02 ? '¡Ve, Poké Ball!' : 'Abriendo...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _FlashPainter extends CustomPainter {
  final double t;
  final Color color;
  final Offset center;
  _FlashPainter({required this.t, required this.color, required this.center});

  static final Paint _rayPaint = Paint();
  static final Paint _starPaint = Paint();
  static final Paint _wash = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    canvas.save();
    try {
      _paintFlash(canvas, size);
      canvas.restore();
    } catch (e, st) {
      canvas.restore();
      debugPrint('FlashPainter error: $e\n$st');
      final i = t < .22 ? t / .22 : (t < .45 ? 1.0 : 1 - (t - .45) / .55);
      canvas.drawRect(Offset.zero & size,
          Paint()..color = const Color(0xFFEAF4FF).withValues(alpha: i));
    }
  }

  void _paintFlash(Canvas canvas, Size size) {
    final maxR = size.longestSide * 1.2;
    // sube rápido → se queda en blanco total → baja
    final intensity = t < .22
        ? t / .22
        : t < .45
            ? 1.0
            : 1 - (t - .45) / .55;

    // Rayos giratorios
    final len = maxR * Curves.easeOut.transform((t * 1.6).clamp(0.0, 1.0));
    _rayPaint.color = const Color(0xFFD6ECFF).withValues(alpha: .65 * intensity);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 1.2);
    const rays = 18;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      const w = .05;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(a - w) * len, math.sin(a - w) * len)
        ..lineTo(math.cos(a + w) * len, math.sin(a + w) * len)
        ..close();
      canvas.drawPath(path, _rayPaint);
    }
    // Estrellitas que salen disparadas
    _starPaint.color = Colors.white.withValues(alpha: intensity);
    for (var i = 0; i < 14; i++) {
      final a = i * 2 * math.pi / 14 + .3;
      final dist = maxR *
          .45 *
          Curves.easeOutCubic.transform(t) *
          (.6 + (i % 3) * .2);
      _drawStar(canvas, Offset(math.cos(a) * dist, math.sin(a) * dist),
          10.0 * (1 - t) + 3, _starPaint);
    }
    canvas.restore();

    // Explosión de luz (círculos sólidos concéntricos, sin degradados)
    final r = math.max(
        1.0, maxR * Curves.easeOutCubic.transform((t * 1.5).clamp(0.0, 1.0)));
    for (var n = 4; n >= 1; n--) {
      _wash.color = Color.lerp(const Color(0xFF9CCBFF), Colors.white, n / 4)!
          .withValues(alpha: .28 * intensity);
      canvas.drawCircle(center, r * (1.05 - n * .2), _wash);
    }

    // Pantalla 100 % blanca
    _wash.color = Color.lerp(const Color(0xFFDDEEFF), Colors.white,
            ((intensity - .6) / .4).clamp(0.0, 1.0))!
        .withValues(alpha: intensity);
    canvas.drawRect(Offset.zero & size, _wash);
  }

  @override
  bool shouldRepaint(covariant _FlashPainter old) =>
      old.t != t || old.color != color || old.center != center;
}

/// Anillo de luz y chispas cuando el Pokémon sale de la Poké Ball.
class _EmergeRingPainter extends CustomPainter {
  final Animation<double> anim;
  _EmergeRingPainter(this.anim) : super(repaint: anim);

  static final Paint _ring = Paint()..style = PaintingStyle.stroke;
  static final Paint _fill = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final k = ((anim.value - _kEmergeStart) / .13).clamp(0.0, 1.0);
    if (k <= 0 || k >= 1) return;
    final c = size.center(Offset.zero);
    final e = Curves.easeOutCubic.transform(k);
    _ring
      ..color = Colors.white.withValues(alpha: 1 - k)
      ..strokeWidth = 14 * (1 - k);
    canvas.drawCircle(c, 30 + e * 160, _ring);
    _ring.strokeWidth = 5 * (1 - k);
    canvas.drawCircle(c, 15 + e * 105, _ring);
    _fill.color = Colors.white.withValues(alpha: 1 - k);
    for (var i = 0; i < 12; i++) {
      final a = i * 2 * math.pi / 12;
      _drawStar(canvas, c + Offset(math.cos(a), math.sin(a)) * (e * 175),
          9 * (1 - k) + 2, _fill);
    }
  }

  @override
  bool shouldRepaint(covariant _EmergeRingPainter old) => false;
}

void _drawStar(Canvas canvas, Offset c, double s, Paint paint) {
  final i = s * .28;
  final path = Path()
    ..moveTo(c.dx, c.dy - s)
    ..lineTo(c.dx + i, c.dy - i)
    ..lineTo(c.dx + s, c.dy)
    ..lineTo(c.dx + i, c.dy + i)
    ..lineTo(c.dx, c.dy + s)
    ..lineTo(c.dx - i, c.dy + i)
    ..lineTo(c.dx - s, c.dy)
    ..lineTo(c.dx - i, c.dy - i)
    ..close();
  canvas.drawPath(path, paint);
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: onTap == null ? .3 : 1,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.white.withValues(alpha: .25),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Pestañas
class _InfoTab extends StatelessWidget {
  final PokemonDetails d;
  final Color color;
  final Color accent;
  const _InfoTab({required this.d, required this.color, required this.accent});

  @override
  Widget build(BuildContext context) {
    final p = d.pokemon;
    final s = d.species;
    final items = <(IconData, String, String)>[
      (Icons.straighten_rounded, 'Altura',
          '${(p.height / 10).toStringAsFixed(1)} m'),
      (Icons.monitor_weight_outlined, 'Peso',
          '${(p.weight / 10).toStringAsFixed(1)} kg'),
      if (s != null && s.genus.isNotEmpty)
        (Icons.category_outlined, 'Categoría',
            s.genus.replaceFirst('Pokémon ', '')),
      if (s != null) (Icons.park_outlined, 'Hábitat', s.habitatName),
      (Icons.bolt_rounded, 'Exp. base', '${p.baseExperience}'),
      if (s != null) ...[
        (Icons.catching_pokemon, 'Captura',
            '${(s.captureRate / 255 * 100).toStringAsFixed(0)} %'),
        (Icons.favorite_border_rounded, 'Amistad', '${s.baseHappiness}'),
        (Icons.public_rounded, 'Generación', s.generation),
      ],
    ];

    return ListView(
      key: ValueKey('info-${p.id}'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        // ----- Descripción
        if (s != null && s.description.isNotEmpty)
          _Appear(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded, color: accent, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.description,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: Color(0xFF4A4D5A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        // ----- Ficha de datos (tarjeta compacta)
        _Appear(
          delay: 80,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E9F0)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: LayoutBuilder(
              builder: (context, box) {
                final cols = box.maxWidth > 620
                    ? 4
                    : box.maxWidth > 420
                        ? 3
                        : 2;
                final w = (box.maxWidth / cols).floorToDouble();
                return Wrap(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      SizedBox(
                        width: w,
                        child: _InfoItem(
                          icon: items[i].$1,
                          label: items[i].$2,
                          value: items[i].$3,
                          color: accent,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        // ----- Habilidades
        _SectionTitle('Habilidades', accent),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < p.abilities.length; i++)
              _Appear(
                delay: 160 + i * 70,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: p.abilities[i].hidden
                        ? Colors.white
                        : color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: .45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p.abilities[i].hidden
                            ? Icons.visibility_off_outlined
                            : Icons.auto_fix_high_rounded,
                        size: 15,
                        color: accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pretty(p.abilities[i].name),
                        style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5),
                      ),
                      if (p.abilities[i].hidden)
                        const Text('  · oculta',
                            style: TextStyle(
                                color: Colors.black38, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        Center(
          child: Text(
            'Datos obtenidos de pokeapi.co/api/v2/pokemon/${p.id}/',
            style: const TextStyle(color: Colors.black38, fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1F2B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final Pokemon p;
  final Color color;
  final Color accent;
  const _StatsTab({required this.p, required this.color, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ValueKey('stats-${p.id}'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      children: [
        for (var i = 0; i < p.stats.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  child: Text(
                    p.stats[i].label,
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${p.stats[i].value}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: _StatBar(
                    key: ValueKey('${p.id}-${p.stats[i].name}'),
                    value: (p.stats[i].value / 200).clamp(0.0, 1.0),
                    color: color,
                    delay: i * 110,
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 30),
        Row(
          children: [
            const SizedBox(
              width: 108,
              child: Text('Total',
                  style: TextStyle(
                      color: Colors.black54, fontWeight: FontWeight.w800)),
            ),
            TweenAnimationBuilder<int>(
              key: ValueKey('total-${p.id}'),
              tween: IntTween(begin: 0, end: p.totalStats),
              duration: const Duration(milliseconds: 1300),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                '$v',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Barra animada con transformación (sin relayout en cada frame).
class _StatBar extends StatefulWidget {
  final double value;
  final Color color;
  final int delay;
  const _StatBar(
      {super.key, required this.value, required this.color, this.delay = 0});

  @override
  State<_StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<_StatBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 12,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFEDEEF2)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.value,
              child: AnimatedBuilder(
                animation: _a,
                builder: (_, c) => Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.diagonal3Values(_a.value, 1, 1),
                  child: c,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lighten(widget.color, .08), darken(widget.color, .12)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvolutionTab extends StatelessWidget {
  final PokemonDetails d;
  final Color color;
  final Color accent;
  final ValueChanged<int> onSelect;
  const _EvolutionTab({
    required this.d,
    required this.color,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final stages = d.species?.evolution ?? const <List<EvoNode>>[];
    if (stages.isEmpty) {
      return const Center(child: Text('Sin datos de evolución'));
    }
    if (stages.length == 1 && stages.first.length == 1) {
      return const Center(child: Text('Este Pokémon no evoluciona'));
    }

    final children = <Widget>[];
    var k = 0;
    for (var i = 0; i < stages.length; i++) {
      if (i > 0) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Icon(Icons.keyboard_double_arrow_down_rounded,
              color: accent, size: 30),
        ));
      }
      children.add(Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final n in stages[i])
            _Appear(
              delay: (k++) * 120,
              child: _EvoTile(
                node: n,
                current: n.id == d.pokemon.id,
                color: color,
                onTap: () => onSelect(n.id),
              ),
            ),
        ],
      ));
    }

    return ListView(
      key: ValueKey('evo-${d.pokemon.id}'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: children,
    );
  }
}

class _EvoTile extends StatelessWidget {
  final EvoNode node;
  final bool current;
  final Color color;
  final VoidCallback onTap;
  const _EvoTile({
    required this.node,
    required this.current,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: current ? color.withValues(alpha: .18) : const Color(0xFFF4F5F9),
              border: Border.all(
                color: current ? color : Colors.transparent,
                width: 3,
              ),
            ),
            child: Image.network(artwork(node.id),
                cacheWidth: 200, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          Text(
            cap(node.name),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Text(
            'N.º ${node.id.toString().padLeft(4, '0')}',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WeakTab extends StatelessWidget {
  final PokemonDetails d;
  final Color accent;
  const _WeakTab({required this.d, required this.accent});

  @override
  Widget build(BuildContext context) {
    final eff = d.effectiveness;
    if (d.types.isEmpty) {
      return const Center(child: Text('Sin datos de tipos'));
    }
    final groups = <(String, double, String)>[
      ('Muy débil', 4, '×4'),
      ('Débil', 2, '×2'),
      ('Resistente', .5, '×½'),
      ('Muy resistente', .25, '×¼'),
      ('Inmune', 0, '×0'),
    ];

    var k = 0;
    return ListView(
      key: ValueKey('weak-${d.pokemon.id}'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        for (final g in groups)
          if (eff.values.any((m) => m == g.$2)) ...[
            Row(
              children: [
                _SectionTitle(g.$1, accent),
                const SizedBox(width: 8),
                Text(g.$3,
                    style: const TextStyle(
                        color: Colors.black45, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in eff.entries)
                  if (e.value == g.$2)
                    _Appear(delay: (k++) * 40, child: TypeChip(type: e.key)),
              ],
            ),
            const SizedBox(height: 22),
          ],
      ],
    );
  }
}

class _MovesTab extends StatelessWidget {
  final Pokemon p;
  final Color color;
  final Color accent;
  const _MovesTab({required this.p, required this.color, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (p.moves.isEmpty) {
      return const Center(child: Text('Sin movimientos registrados'));
    }
    return ListView(
      key: ValueKey('moves-${p.id}'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        Row(
          children: [
            Icon(Icons.touch_app_rounded, color: accent, size: 18),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Toca un movimiento para verlo en acción',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < p.moves.length; i++)
              _Appear(
                delay: math.min(i * 25, 600),
                child: _MoveChip(
                  name: p.moves[i],
                  color: color,
                  accent: accent,
                  onTap: () => showMoveDialog(context, p, p.moves[i]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MoveChip extends StatelessWidget {
  final String name;
  final Color color;
  final Color accent;
  final VoidCallback onTap;
  const _MoveChip({
    required this.name,
    required this.color,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: .1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: .35)),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, size: 16, color: accent),
              const SizedBox(width: 4),
              Text(
                pretty(name),
                style: TextStyle(color: accent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  PARTÍCULAS POR TIPO (se usan en hover y en movimientos)
// ============================================================================

final Paint _pFill = Paint();
final Paint _pLine = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

double _seg(double x, double s, double e) =>
    ((x - s) / (e - s)).clamp(0.0, 1.0);

/// 0 → 1 → 0 dentro del intervalo (curva de campana)
double _bell(double x, double s, double e) {
  final k = _seg(x, s, e);
  return k <= 0 || k >= 1 ? 0.0 : math.sin(k * math.pi);
}

Path _flamePath(double s) => Path()
  ..moveTo(0, -s * 1.3)
  ..quadraticBezierTo(s, -s * .1, s * .6, s * .5)
  ..arcToPoint(Offset(-s * .6, s * .5), radius: Radius.circular(s * .62))
  ..quadraticBezierTo(-s, -s * .1, 0, -s * 1.3)
  ..close();

/// Partícula con forma y color según el TIPO.
void paintTypeParticle(Canvas canvas, String type, Offset p, double s,
    double rot, double alpha) {
  if (alpha <= 0 || s <= 0) return;
  final al = alpha.clamp(0.0, 1.0);
  final base = typeColor(type);
  final c = base.withValues(alpha: al);
  final l = Color.lerp(base, Colors.white, .55)!.withValues(alpha: al);
  canvas.save();
  canvas.translate(p.dx, p.dy);
  canvas.rotate(rot);
  switch (type) {
    case 'fire':
      _pFill.color = c;
      canvas.drawPath(_flamePath(s), _pFill);
      _pFill.color = const Color(0xFFFFE066).withValues(alpha: al);
      canvas.drawCircle(Offset(0, s * .25), s * .4, _pFill);
    case 'water' || 'poison':
      _pFill.color = c;
      canvas.drawCircle(Offset.zero, s * .8, _pFill);
      _pFill.color = Colors.white.withValues(alpha: al * .8);
      canvas.drawCircle(Offset(-s * .25, -s * .25), s * .22, _pFill);
    case 'electric':
      _pLine
        ..color = const Color(0xFFFFE14D).withValues(alpha: al)
        ..strokeWidth = s * .35;
      canvas.drawPath(
        Path()
          ..moveTo(-s, -s)
          ..lineTo(0, -s * .1)
          ..lineTo(-s * .3, s * .1)
          ..lineTo(s, s),
        _pLine,
      );
    case 'grass' || 'bug':
      _pFill.color = c;
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * .9),
          _pFill);
      _pLine
        ..color = l
        ..strokeWidth = s * .12;
      canvas.drawLine(Offset(-s, 0), Offset(s, 0), _pLine);
    case 'ice':
      _pLine
        ..color = l
        ..strokeWidth = s * .25;
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(Offset(-s, 0), Offset(s, 0), _pLine);
        canvas.rotate(math.pi / 3);
      }
    case 'ground' || 'rock':
      _pFill.color = c;
      canvas.drawPath(
        Path()
          ..moveTo(-s, -s * .4)
          ..lineTo(-s * .2, -s)
          ..lineTo(s, -s * .5)
          ..lineTo(s * .7, s * .8)
          ..lineTo(-s * .6, s * .9)
          ..close(),
        _pFill,
      );
    case 'ghost' || 'dark' || 'dragon':
      _pFill.color = base.withValues(alpha: al * .35);
      canvas.drawCircle(Offset.zero, s * 1.4, _pFill);
      _pFill.color = c;
      canvas.drawCircle(Offset.zero, s * .75, _pFill);
    case 'flying':
      _pLine
        ..color = Colors.white.withValues(alpha: al)
        ..strokeWidth = s * .3;
      canvas.drawLine(Offset(-s * 1.4, 0), Offset(s * 1.4, 0), _pLine);
    default: // normal, lucha, psíquico, hada, acero
      _pFill.color = type == 'normal' ? Colors.white.withValues(alpha: al) : l;
      _drawStar(canvas, Offset.zero, s * 1.2, _pFill);
  }
  canvas.restore();
}

// ============================================================================
//  ANIMACIÓN CARACTERÍSTICA AL PASAR EL CURSOR (según su tipo)
// ============================================================================

class _HoverPokemon extends StatefulWidget {
  final bool active;
  final String type;
  final Widget child;
  const _HoverPokemon(
      {required this.active, required this.type, required this.child});

  @override
  State<_HoverPokemon> createState() => _HoverPokemonState();
}

class _HoverPokemonState extends State<_HoverPokemon>
    with SingleTickerProviderStateMixin {
  // OPTIMIZACIÓN: el controlador se crea solo cuando se usa por 1.ª vez
  AnimationController? _c;
  AnimationController get _ctrl => _c ??= AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _HoverPokemon old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _ctrl.repeat();
    } else if (!widget.active && old.active) {
      _ctrl.animateTo(0, duration: const Duration(milliseconds: 220));
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Widget _motion(double v, Widget child) {
    final w = v * 2 * math.pi;
    var dx = 0.0, dy = 0.0, rot = 0.0, sx = 1.0, sy = 1.0;
    switch (widget.type) {
      case 'fire': // flama que palpita
        {
          sx = 1 + math.sin(w * 3) * .03;
          sy = 1 + math.sin(w * 3 + 1) * .06;
        }
      case 'water': // flota como en olas
        {
          dy = math.sin(w) * 6;
          rot = math.sin(w) * .05;
        }
      case 'electric': // chispazos
        {
          final zap = (v * 6) % 1 < .25;
          dx = zap ? math.sin(w * 24) * 2.5 : 0;
          sy = 1 + math.sin(w * 2) * .03;
        }
      case 'grass' || 'bug': // se mece con el viento
        {
          rot = math.sin(w) * .09;
          sy = 1 + math.sin(w * 2) * .025;
        }
      case 'flying': // vuela
        {
          dy = -8 - math.sin(w) * 8;
          rot = math.sin(w) * .07;
        }
      case 'ghost' || 'psychic' || 'fairy' || 'dragon': // levita
        {
          dy = -6 + math.sin(w) * 7;
          sx = sy = 1 + math.sin(w * 2) * .03;
        }
      case 'ground' || 'rock' || 'steel' || 'fighting': // pisotón
        {
          final k = (v * 2) % 1;
          dy = -math.sin(k * math.pi) * 12;
          final land = k < .12 ? 1 - k / .12 : 0.0;
          sx = 1 + land * .12;
          sy = 1 - land * .12;
        }
      case 'poison': // gelatina
        {
          sx = 1 + math.sin(w * 2) * .06;
          sy = 1 - math.sin(w * 2) * .06;
        }
      case 'ice': // tiembla de frío
        {
          dx = math.sin(w * 14) * 1.2;
          sy = 1 + math.sin(w) * .02;
        }
      default: // brinquito feliz
        {
          final k = (v * 2) % 1;
          dy = -math.sin(k * math.pi) * 10;
          sy = 1 + math.sin(k * 2 * math.pi) * .04;
          sx = 2 - sy;
        }
    }
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(sx, sy, 1)..rotateZ(rot),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _HoverFxPainter(c, widget.type, widget.active),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: c,
          child: widget.child,
          builder: (_, child) => _motion(c.value, child!),
        ),
      ],
    );
  }
}

class _HoverFxPainter extends CustomPainter {
  final Animation<double> anim;
  final String type;
  final bool active;
  _HoverFxPainter(this.anim, this.type, this.active) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final v = anim.value;
    final w = size.width, h = size.height;
    for (var i = 0; i < 7; i++) {
      final ph = (v + i / 7) % 1;
      final sx = (i * .137 + .1) % 1;
      Offset p;
      var s = 7.0;
      var rot = ph * 6;
      var alpha = math.sin(ph * math.pi);
      switch (type) {
        case 'fire' || 'water' || 'poison' || 'ghost': // suben
          p = Offset(w * (.15 + sx * .7), h * (1 - ph * 1.05));
        case 'grass' || 'bug' || 'ice': // caen
          p = Offset(w * (.1 + sx * .8) + math.sin(ph * 6 + i) * 8, h * ph - 6);
        case 'psychic' || 'fairy' || 'dragon' || 'normal' || 'dark': // orbitan
          {
            final a = ph * 2 * math.pi;
            p = Offset(
                w / 2 + math.cos(a) * w * .48, h * .55 + math.sin(a) * h * .22);
            s = 6;
          }
        case 'electric': // chispas alrededor
          {
            final a = i * 2 * math.pi / 7 + v * 2;
            final rr = .42 * (.7 + ph * .3);
            p = Offset(
                w / 2 + math.cos(a) * w * rr, h * .5 + math.sin(a) * h * rr);
            alpha = ph < .5 ? 1.0 : 0.0;
            s = 8;
          }
        case 'flying': // ráfagas
          p = Offset(w * ph * 1.2 - w * .1, h * (.2 + sx * .6));
          rot = 0;
        default: // polvo en el piso
          p = Offset(w * (.2 + sx * .6) + (ph - .5) * 30,
              h * .95 - math.sin(ph * math.pi) * 22);
          s = 5;
      }
      paintTypeParticle(canvas, type, p, s, rot, alpha);
    }
  }

  @override
  bool shouldRepaint(covariant _HoverFxPainter old) =>
      old.active != active || old.type != type;
}

// ============================================================================
//  ANIMACIÓN DE MOVIMIENTOS
//  El efecto se elige con los datos reales del movimiento (API):
//  tipo → partículas (llamas, burbujas, rayos, hojas, hielo, rocas...)
//  forma → proyectil, rayo, golpe, tajo, aura, lluvia, terremoto, viento,
//          absorción o remolino.
// ============================================================================

enum FxStyle {
  projectile,
  beam,
  impact,
  slash,
  aura,
  rain,
  quake,
  wind,
  drain,
  spiral,
}

FxStyle fxStyleFor(MoveInfo m) {
  final n = m.apiName;
  bool has(List<String> keys) => keys.any(n.contains);

  if (m.damageClass == 'status') {
    return has(['rain', 'hail', 'sandstorm', 'sunny', 'snow'])
        ? FxStyle.rain
        : FxStyle.aura;
  }
  if (has(['drain', 'absorb', 'leech', 'dream-eater'])) return FxStyle.drain;
  if (has(['quake', 'earth', 'magnitude', 'bulldoze', 'fissure', 'dig'])) {
    return FxStyle.quake;
  }
  if (has([
    'punch', 'kick', 'tackle', 'slam', 'strike', 'headbutt', 'body',
    'stomp', 'crash', 'smash', 'rush', 'take-down', 'double-edge', 'hammer',
  ])) {
    return FxStyle.impact;
  }
  if (has([
    'slash', 'cut', 'claw', 'scratch', 'fang', 'bite', 'fury', 'razor',
    'blade', 'scissor', 'edge', 'peck',
  ])) {
    return FxStyle.slash;
  }
  if (has([
    'storm', 'hail', 'blizzard', 'thunder', 'meteor', 'slide', 'avalanche',
    'rain', 'shower',
  ])) {
    return FxStyle.rain;
  }
  if (has(['wind', 'gust', 'tornado', 'hurricane', 'air', 'twister'])) {
    return FxStyle.wind;
  }
  if (has(['spin', 'vortex', 'whirl', 'swirl', 'wrap', 'bind', 'trap'])) {
    return FxStyle.spiral;
  }
  if (has([
    'beam', 'ray', 'cannon', 'blast', 'pulse', 'hyper', 'laser',
    'flamethrower', 'hydro', 'solar', 'jet',
  ])) {
    return FxStyle.beam;
  }
  return m.damageClass == 'physical' ? FxStyle.impact : FxStyle.projectile;
}

double _hitTime(FxStyle s) => switch (s) {
      FxStyle.projectile => .55,
      FxStyle.beam => .55,
      FxStyle.impact => .35,
      FxStyle.slash => .15,
      FxStyle.rain => .35,
      FxStyle.quake => .2,
      FxStyle.wind => .45,
      FxStyle.drain => .1,
      FxStyle.spiral => .2,
      FxStyle.aura => 2.0,
    };

String _styleName(FxStyle s) => switch (s) {
      FxStyle.projectile => 'Proyectil',
      FxStyle.beam => 'Rayo',
      FxStyle.impact => 'Golpe',
      FxStyle.slash => 'Tajo',
      FxStyle.aura => 'Aura',
      FxStyle.rain => 'Desde el cielo',
      FxStyle.quake => 'Terremoto',
      FxStyle.wind => 'Viento',
      FxStyle.drain => 'Absorción',
      FxStyle.spiral => 'Remolino',
    };

void showMoveDialog(BuildContext context, Pokemon p, String move) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => _MoveDialog(pokemon: p, move: move),
    transitionBuilder: (_, a, __, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: Tween(begin: .85, end: 1.0)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
        child: child,
      ),
    ),
  );
}

class _MoveDialog extends StatefulWidget {
  final Pokemon pokemon;
  final String move;
  const _MoveDialog({required this.pokemon, required this.move});

  @override
  State<_MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends State<_MoveDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));
  late final Future<MoveInfo> _future = PokeApi.move(widget.move);

  @override
  void initState() {
    super.initState();
    _future.then((_) {
      if (mounted) _c.repeat();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: FutureBuilder<MoveInfo>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                        child: Text('No se pudo cargar el movimiento')),
                  );
                }
                final m = snap.data;
                if (m == null) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: _SpinningBall(size: 48)),
                  );
                }
                final style = fxStyleFor(m);
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MoveStage(
                        anim: _c,
                        move: m,
                        style: style,
                        pokemon: widget.pokemon,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                TypeChip(type: m.type),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${m.categoryName} · ${_styleName(style)}',
                              style: const TextStyle(
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _MoveStat('Poder', m.power?.toString() ?? '—'),
                                const SizedBox(width: 8),
                                _MoveStat('Precisión',
                                    m.accuracy == null ? '—' : '${m.accuracy}%'),
                                const SizedBox(width: 8),
                                _MoveStat('PP', m.pp?.toString() ?? '—'),
                              ],
                            ),
                            if (m.description.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                m.description,
                                style: const TextStyle(
                                  height: 1.45,
                                  color: Color(0xFF4A4D5A),
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveStat extends StatelessWidget {
  final String label;
  final String value;
  const _MoveStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label,
                style: const TextStyle(color: Colors.black45, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

/// Escenario de batalla: tu Pokémon ataca a un rival con animación viva
/// (respira, se prepara, ataca, regresa; el rival recibe el golpe).
class _MoveStage extends StatelessWidget {
  final Animation<double> anim;
  final MoveInfo move;
  final FxStyle style;
  final Pokemon pokemon;
  const _MoveStage({
    required this.anim,
    required this.move,
    required this.style,
    required this.pokemon,
  });

  static const double _h = 270;

  int get _rivalId {
    var h = 7;
    for (final c in move.apiName.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    var id = h % 151 + 1;
    if (id == pokemon.id) id = id % 151 + 1;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final col = typeColor(move.type);
    final hit = _hitTime(style);
    final physical = style == FxStyle.impact || style == FxStyle.slash;
    final power = move.power;
    final dmg = power == null ? 0.0 : (power / 160).clamp(.15, .75).toDouble();

    // Imágenes HD; se crean una vez y la animación solo las transforma
    final attacker = RepaintBoundary(
      child: Image.network(pokemon.imageUrl,
          width: 140,
          height: 140,
          cacheWidth: 280,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium),
    );
    final rival = RepaintBoundary(
      child: Image.network(artwork(_rivalId),
          width: 112,
          height: 112,
          cacheWidth: 224,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium),
    );

    return RepaintBoundary(
      child: SizedBox(
        height: _h,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          final a = Offset(w * .26, _h * .66);
          final b = Offset(w * .74, _h * .42);

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(Colors.white, col, .38)!,
                        Color.lerp(Colors.white, col, .1)!,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: a.dx - 80,
                top: a.dy + 44,
                width: 160,
                height: 28,
                child: _Platform(color: col),
              ),
              Positioned(
                left: b.dx - 64,
                top: b.dy + 40,
                width: 128,
                height: 24,
                child: _Platform(color: col),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: anim,
                  builder: (context, _) {
                    final t = anim.value;

                    // ---------- atacante: respira, se prepara, ataca, regresa
                    final breathe = math.sin(t * 4 * math.pi);
                    final antic = _bell(t, .06, .24);
                    var lunge = 0.0;
                    if (physical) {
                      lunge = t < hit
                          ? Curves.easeInCubic.transform(_seg(t, .2, hit))
                          : 1 -
                              Curves.easeOutBack
                                  .transform(_seg(t, hit, hit + .28));
                    }
                    final cast =
                        physical ? 0.0 : _bell(t, .1, math.min(hit + .15, .95));
                    final jump =
                        style == FxStyle.quake ? _bell(t, .04, .2) : 0.0;
                    final aSx =
                        1 + breathe * .015 + antic * .1 + lunge * .08 - cast * .03;
                    final aSy =
                        1 - breathe * .015 - antic * .1 + cast * .08 + jump * .1;
                    final aRot = -antic * .14 + lunge * .12;
                    final ax = a.dx - 70 + (b.dx - a.dx) * .55 * lunge - antic * 16;
                    final ay = a.dy - 72 + (b.dy - a.dy) * .55 * lunge - jump * 50;

                    // ---------- rival: recibe el golpe
                    final hk = _seg(t, hit, hit + .35);
                    final hitOn = hk > 0 && hk < 1 && dmg > 0;
                    final knock = hitOn ? math.sin(hk * math.pi) * 20 : 0.0;
                    final shake =
                        hitOn ? math.sin(hk * 40) * 6 * (1 - hk) : 0.0;
                    final squash = hitOn ? math.sin(hk * math.pi) * .14 : 0.0;
                    final blink = hitOn && (hk * 7).floor().isOdd;
                    final rBreathe = math.sin(t * 4 * math.pi + 1.3);
                    final hp = 1 -
                        dmg * Curves.easeOut.transform(_seg(t, hit + .05, hit + .45));

                    // ---------- cámara
                    var cam = hitOn
                        ? Offset(math.sin(hk * 50) * 5 * (1 - hk),
                            math.cos(hk * 43) * 4 * (1 - hk))
                        : Offset.zero;
                    if (style == FxStyle.quake && t > .2 && t < .7) {
                      cam += Offset(math.sin(t * 90) * 5, 0);
                    }

                    Widget rivalW = rival;
                    if (hitOn && hk < .5) {
                      rivalW = ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.white.withValues(alpha: (1 - hk * 2) * .85),
                          BlendMode.srcATop,
                        ),
                        child: rival,
                      );
                    }

                    return Transform.translate(
                      offset: cam,
                      child: Stack(
                        children: [
                          if (cast > 0)
                            Positioned(
                              left: a.dx - 85,
                              top: a.dy - 95,
                              width: 170,
                              height: 170,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [
                                    col.withValues(alpha: .55 * cast),
                                    col.withValues(alpha: 0),
                                  ]),
                                ),
                              ),
                            ),
                          Positioned(
                            left: b.dx - 56 + knock + shake,
                            top: b.dy - 76 - rBreathe * 2,
                            child: Opacity(
                              opacity: blink ? .35 : 1,
                              child: Transform(
                                alignment: Alignment.bottomCenter,
                                transform: Matrix4.diagonal3Values(
                                    1 + squash, 1 - squash + rBreathe * .012, 1),
                                child: rivalW,
                              ),
                            ),
                          ),
                          Positioned(
                            left: ax,
                            top: ay,
                            child: Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.diagonal3Values(aSx, aSy, 1)
                                ..rotateZ(aRot),
                              child: attacker,
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _MoveFxPainter(
                                t: t,
                                type: move.type,
                                style: style,
                                a: a,
                                b: b,
                              ),
                            ),
                          ),
                          if (hitOn)
                            Positioned(
                              left: b.dx - 22,
                              top: b.dy - 100 - hk * 34,
                              child: Opacity(
                                opacity: (1 - hk).clamp(0.0, 1.0),
                                child: Text(
                                  '-$power',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black54,
                                          blurRadius: 6,
                                          offset: Offset(0, 2)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (hitOn && hk < .12)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: ColoredBox(
                                  color: Colors.white
                                      .withValues(alpha: (1 - hk / .12) * .45),
                                ),
                              ),
                            ),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: _HpBox(name: 'Rival', hp: hp),
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: _HpBox(name: pokemon.displayName, hp: 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _HpBox extends StatelessWidget {
  final String name;
  final double hp;
  const _HpBox({required this.name, required this.hp});

  @override
  Widget build(BuildContext context) {
    final v = hp.clamp(0.0, 1.0);
    final color = v > .5
        ? const Color(0xFF3BC85A)
        : v > .2
            ? const Color(0xFFF2B21B)
            : const Color(0xFFE5483A);
    return Container(
      width: 150,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .93),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('PS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE08A00))),
              const SizedBox(width: 5),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Color(0xFFE4E6EC)),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: v,
                          child: ColoredBox(color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Platform extends StatelessWidget {
  final Color color;
  const _Platform({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.elliptical(100, 20)),
        color: Color.lerp(color, Colors.black, .15)!.withValues(alpha: .35),
      ),
    );
  }
}

class _MoveFxPainter extends CustomPainter {
  final double t;
  final String type;
  final FxStyle style;
  final Offset a;
  final Offset b;
  _MoveFxPainter({
    required this.t,
    required this.type,
    required this.style,
    required this.a,
    required this.b,
  });

  // Paints reutilizados (cero basura por frame)
  static final Paint _fill = Paint();
  static final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  Color get _c => typeColor(type);
  Color get _light => Color.lerp(_c, Colors.white, .55)!;

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case FxStyle.projectile:
        _projectile(canvas);
      case FxStyle.beam:
        _beam(canvas);
      case FxStyle.impact:
        _impact(canvas);
      case FxStyle.slash:
        _slash(canvas);
      case FxStyle.aura:
        _aura(canvas);
      case FxStyle.rain:
        _rain(canvas, size);
      case FxStyle.quake:
        _quake(canvas, size);
      case FxStyle.wind:
        _wind(canvas);
      case FxStyle.drain:
        _drain(canvas);
      case FxStyle.spiral:
        _spiral(canvas);
    }
  }

  // ------------------------------------------------ estilos
  void _projectile(Canvas canvas) {
    for (var i = 0; i < 7; i++) {
      final k = _seg(t, i * .05, i * .05 + .5);
      if (k <= 0 || k >= 1) continue;
      final pos = Offset.lerp(a, b, Curves.easeIn.transform(k))! +
          Offset(0, -math.sin(k * math.pi) * 30);
      _particle(canvas, pos, 11 - i * .6, t * 12 + i, 1);
    }
    _burst(canvas, b, _seg(t, .55, .95));
  }

  void _beam(Canvas canvas) {
    final charge = _seg(t, 0, .15);
    if (charge > 0 && t < .6) {
      _fill.color = _light.withValues(alpha: .7);
      canvas.drawCircle(a, 8 + charge * 18 + math.sin(t * 50) * 3, _fill);
    }
    final on = _seg(t, .12, .3);
    final off = 1 - _seg(t, .62, .78);
    if (on > 0 && off > 0) {
      final end = Offset.lerp(a, b, on)!;
      final w = (18 + math.sin(t * 60) * 5) * off;
      _line
        ..color = _c.withValues(alpha: .85 * off)
        ..strokeWidth = w;
      canvas.drawLine(a, end, _line);
      _line
        ..color = Colors.white.withValues(alpha: off)
        ..strokeWidth = w * .4;
      canvas.drawLine(a, end, _line);
      final dir = b - a;
      final nrm = Offset(-dir.dy, dir.dx) / dir.distance;
      for (var i = 0; i < 9; i++) {
        final f = ((i / 9 + t * 3) % 1) * on;
        final pos = Offset.lerp(a, b, f)! +
            nrm * (math.sin(i * 7 + t * 30) * w * .7);
        _particle(canvas, pos, 6, t * 10 + i, off);
      }
    }
    _burst(canvas, b, _seg(t, .55, .9));
  }

  void _impact(Canvas canvas) {
    // líneas de velocidad mientras embiste
    final dash = _seg(t, .1, .35);
    if (dash > 0 && dash < 1) {
      _line
        ..color = Colors.white.withValues(alpha: .8 * (1 - dash))
        ..strokeWidth = 3;
      final p = Offset.lerp(a, b, dash * .55)!;
      for (var i = -2; i <= 2; i++) {
        canvas.drawLine(p + Offset(-70, i * 12.0), p + Offset(-30, i * 12.0), _line);
      }
    }
    final k = _seg(t, .35, .65);
    if (k > 0 && k < 1) {
      _fill.color = _light.withValues(alpha: 1 - k);
      _drawStar(canvas, b, 26 + 60 * Curves.easeOut.transform(k), _fill);
      _fill.color = Colors.white.withValues(alpha: 1 - k);
      _drawStar(canvas, b, 14 + 30 * k, _fill);
    }
    _burst(canvas, b, _seg(t, .35, .8), n: 10, dist: 75);
  }

  void _slash(Canvas canvas) {
    for (var i = 0; i < 3; i++) {
      final k = _seg(t, .12 + i * .12, .4 + i * .12);
      if (k <= 0 || k >= 1) continue;
      final start = b + Offset(-55, -55 + i * 22.0);
      final end = b + Offset(55, 30 + i * 22.0);
      final drawK = Curves.easeOut.transform((k * 1.8).clamp(0.0, 1.0));
      final p2 = Offset.lerp(start, end, drawK)!;
      final alpha = 1 - ((k - .55) / .45).clamp(0.0, 1.0);
      _line
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = 8;
      canvas.drawLine(start, p2, _line);
      _line
        ..color = _c.withValues(alpha: alpha)
        ..strokeWidth = 3;
      canvas.drawLine(start, p2, _line);
    }
    _burst(canvas, b, _seg(t, .2, .6), n: 8, dist: 55);
  }

  void _aura(Canvas canvas) {
    for (var i = 0; i < 3; i++) {
      final k = (t + i / 3) % 1;
      _line
        ..color = _light.withValues(alpha: (1 - k) * .85)
        ..strokeWidth = 4;
      canvas.drawCircle(a, 40 + k * 80, _line);
    }
    for (var i = 0; i < 8; i++) {
      final ang = t * 2 * math.pi + i * 2 * math.pi / 8;
      final rr = 70 + math.sin(t * 4 * math.pi + i) * 8;
      final pos =
          a + Offset(math.cos(ang) * rr, math.sin(ang) * rr * .5 - 10);
      _particle(canvas, pos, 7, ang, .9);
    }
  }

  void _rain(Canvas canvas, Size size) {
    for (var i = 0; i < 16; i++) {
      final x = b.dx + (i - 8) * 15 + math.sin(i * 3.1) * 8;
      final f = (t * 1.3 + i * .137) % 1;
      final y = -20 + f * (b.dy + 60);
      final alpha = f < .85 ? 1.0 : (1 - f) / .15;
      _particle(canvas, Offset(x, y), 8, math.pi / 2, alpha);
    }
    if (type == 'electric') {
      final k = _seg(t, .3, .5);
      if (k > 0 && k < 1) {
        final path = Path()..moveTo(b.dx + 10, 0);
        var y = 0.0;
        var left = true;
        while (y < b.dy) {
          y += 22;
          path.lineTo(b.dx + (left ? -14 : 14), math.min(y, b.dy));
          left = !left;
        }
        _line
          ..color = const Color(0xFFFFE14D).withValues(alpha: 1 - k)
          ..strokeWidth = 8;
        canvas.drawPath(path, _line);
        _line
          ..color = Colors.white.withValues(alpha: 1 - k)
          ..strokeWidth = 3;
        canvas.drawPath(path, _line);
      }
    }
    _burst(canvas, b, _seg(t, .35, .7), n: 8, dist: 50);
  }

  void _quake(Canvas canvas, Size size) {
    final ground = size.height * .9;
    final crack = _seg(t, .15, .4);
    if (crack > 0) {
      final alpha = 1 - _seg(t, .75, .95);
      final path = Path()..moveTo(0, ground);
      final len = size.width * crack;
      for (var x = 0.0; x < len; x += 18) {
        path.lineTo(x, ground + ((x ~/ 18).isEven ? -6 : 6));
      }
      _line
        ..color = const Color(0xFF3A2A1A).withValues(alpha: alpha)
        ..strokeWidth = 4;
      canvas.drawPath(path, _line);
    }
    for (var i = 0; i < 10; i++) {
      final k = _seg(t, .2 + i * .03, .55 + i * .03);
      if (k <= 0 || k >= 1) continue;
      final x = size.width * (.08 + i * .09);
      final y = ground - math.sin(k * math.pi) * (40 + (i % 3) * 25);
      _particle(canvas, Offset(x, y), 9, k * 6, 1);
    }
  }

  void _wind(Canvas canvas) {
    for (var i = 0; i < 6; i++) {
      final k = _seg(t, i * .07, i * .07 + .55);
      if (k <= 0 || k >= 1) continue;
      final cpos = Offset.lerp(a, b, Curves.easeInOut.transform(k))! +
          Offset(0, (i - 3) * 14.0);
      final path = Path()
        ..moveTo(cpos.dx - 45, cpos.dy)
        ..quadraticBezierTo(cpos.dx, cpos.dy - 20, cpos.dx + 45, cpos.dy);
      _line
        ..color = Colors.white.withValues(alpha: (1 - k) * .9)
        ..strokeWidth = 4;
      canvas.drawPath(path, _line);
      _particle(canvas, cpos, 6, k * 8, 1 - k);
    }
    _burst(canvas, b, _seg(t, .45, .85), n: 8, dist: 55);
  }

  void _drain(Canvas canvas) {
    for (var i = 0; i < 9; i++) {
      final k = _seg(t, i * .06, i * .06 + .5);
      if (k <= 0 || k >= 1) continue;
      final pos = Offset.lerp(b, a, Curves.easeInOut.transform(k))! +
          Offset(math.sin(k * math.pi * 2 + i) * 20, 0);
      _particle(canvas, pos, 8, k * 6, 1);
    }
    final g = _seg(t, .5, .95);
    if (g > 0 && g < 1) {
      _fill.color = _light.withValues(alpha: (1 - (g - .5).abs() * 2) * .55);
      canvas.drawCircle(a, 55, _fill);
    }
  }

  void _spiral(Canvas canvas) {
    final shrink = _seg(t, .1, .8);
    final alpha = t < .85 ? 1.0 : (1 - t) / .15;
    for (var i = 0; i < 12; i++) {
      final ang = t * 4 * math.pi + i * 2 * math.pi / 12;
      final rr = 80 * (1 - shrink * .75) + 10;
      final pos = b + Offset(math.cos(ang) * rr, math.sin(ang) * rr * .6);
      _particle(canvas, pos, 8, ang, alpha);
    }
    _burst(canvas, b, _seg(t, .78, 1), n: 10, dist: 60);
  }

  // ------------------------------------------------ piezas
  void _burst(Canvas canvas, Offset p, double k,
      {int n = 12, double dist = 80}) {
    if (k <= 0 || k >= 1) return;
    final e = Curves.easeOutCubic.transform(k);
    _line
      ..color = _light.withValues(alpha: 1 - k)
      ..strokeWidth = 6 * (1 - k);
    canvas.drawCircle(p, 20 + e * dist * .8, _line);
    for (var i = 0; i < n; i++) {
      final ang = i * 2 * math.pi / n;
      _particle(canvas, p + Offset(math.cos(ang), math.sin(ang)) * (e * dist),
          9 * (1 - k * .5), ang, 1 - k);
    }
    _fill.color = Colors.white.withValues(alpha: (1 - k) * .8);
    canvas.drawCircle(p, 26 * (1 - k) + 6, _fill);
  }

  void _particle(Canvas canvas, Offset p, double s, double rot, double alpha) =>
      paintTypeParticle(canvas, type, p, s, rot, alpha);

  @override
  bool shouldRepaint(covariant _MoveFxPainter old) =>
      old.t != t || old.type != type || old.style != style;
}

// ============================================================================
//  WIDGETS REUTILIZABLES
// ============================================================================

class TypeChip extends StatelessWidget {
  final String type;
  final bool onColor;
  final bool small;
  const TypeChip(
      {super.key, required this.type, this.onColor = false, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 9, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: onColor ? Colors.white.withValues(alpha: .28) : typeColor(type),
        borderRadius: BorderRadius.circular(20),
        border: onColor
            ? Border.all(color: Colors.white.withValues(alpha: .5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeIcon(type), color: Colors.white, size: small ? 11 : 14),
          SizedBox(width: small ? 4 : 6),
          Text(
            typeName(type).toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: small ? 10 : 12,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

/// Hace flotar a su hijo arriba/abajo usando un controlador compartido.
class _Floating extends StatelessWidget {
  final Animation<double> loop;
  final double amount;
  final int speed;
  final Widget child;
  const _Floating({
    required this.loop,
    required this.child,
    this.amount = 10,
    this.speed = 2,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      child: RepaintBoundary(child: child),
      builder: (_, c) => Transform.translate(
        offset: Offset(0, math.sin(loop.value * 2 * math.pi * speed) * amount),
        child: c,
      ),
    );
  }
}

/// Aparece con fade + deslizamiento (usa transiciones, no reconstruye).
class _Appear extends StatefulWidget {
  final Widget child;
  final int delay;
  final double offsetY;
  const _Appear({required this.child, this.delay = 0, this.offsetY = 18});

  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.delay == 0) {
      _c.forward();
    } else {
      _t = Timer(Duration(milliseconds: widget.delay), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        child: widget.child,
        builder: (_, c) => Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _curve.value)),
          child: c,
        ),
      ),
    );
  }
}

class _GridLoading extends StatelessWidget {
  const _GridLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(60),
      child: Column(
        children: [
          _SpinningBall(size: 56),
          SizedBox(height: 14),
          Text('Cargando Pokédex...',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SpinningBall extends StatefulWidget {
  final double size;
  const _SpinningBall({required this.size});

  @override
  State<_SpinningBall> createState() => _SpinningBallState();
}

class _SpinningBallState extends State<_SpinningBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _c,
        child: RepaintBoundary(child: PokeBall(size: widget.size)),
      );
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.black26),
          SizedBox(height: 10),
          Text('Ningún Pokémon coincide con tu búsqueda'),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBox({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.black26),
          const SizedBox(height: 12),
          const Text('No se pudo conectar con la PokeAPI',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kRed),
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorPage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kBg,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            Expanded(child: Center(child: _ErrorBox(onRetry: onRetry))),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 90),
      color: kInk,
      child: const Column(
        children: [
          PokeBall(size: 40),
          SizedBox(height: 10),
          Text(
            'POKÉMON · Práctica académica 02',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Flutter + Dio · Datos de pokeapi.co',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//  DIBUJOS (CustomPainter)
// ============================================================================

/// Poké Ball a color.
class PokeBall extends StatelessWidget {
  final double size;
  const PokeBall({super.key, required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: PokeBallPainter()),
      );
}

/// Poké Ball en 3D REAL: los dos hemisferios se generan como puntos 3D,
/// se rotan (rodar / abrir la tapa sobre la bisagra trasera), se proyectan
/// con perspectiva y se rellenan con su contorno. La luz queda fija.
class PokeBallPainter extends CustomPainter {
  /// 0 = cerrada, 1 = tapa abierta
  final double open;

  /// brillo del botón 0..1
  final double glow;

  /// giro al rodar (radianes)
  final double spin;

  PokeBallPainter({this.open = 0, this.glow = 0, this.spin = 0});

  static const double _pitch = .34; // cámara un poco arriba
  static const int _lat = 9;
  static const int _lon = 44;
  static const _ink = Color(0xFF15151C);
  static const _white = Color(0xFFF4F5F8);

  @override
  void paint(Canvas canvas, Size size) {
    // A prueba de fallos: si algo truena, dibuja una versión simple
    // en vez de dejar la pantalla en blanco, y avisa en la consola (F12).
    canvas.save();
    try {
      _paint3D(canvas, size);
      canvas.restore();
    } catch (e, st) {
      canvas.restore();
      debugPrint('PokeBallPainter error: $e\n$st');
      _paintFallback(canvas, size);
    }
  }

  /// Versión 2D simple (solo círculos y óvalos sólidos): nunca falla.
  void _paintFallback(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final k = open.clamp(0.0, 1.0);
    final lift = r * .72 * k;
    final ink = Paint()..color = _ink;
    final top = Rect.fromCircle(center: c.translate(0, -lift), radius: r);
    final bot = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(bot, 0, math.pi, true, Paint()..color = _white);
    canvas.drawArc(top, math.pi, math.pi, true, Paint()..color = kRed);
    if (k > 0) {
      canvas.drawOval(
          Rect.fromCenter(center: c, width: r * 2, height: r * .55 * k),
          Paint()..color = const Color(0xFFB9BDC8));
      canvas.drawOval(
          Rect.fromCenter(
              center: c.translate(0, -lift), width: r * 2, height: r * .45 * k),
          Paint()..color = const Color(0xFFC9CCD6));
    }
    canvas.drawRect(
        Rect.fromLTRB(top.left, top.center.dy - r * .08, top.right,
            top.center.dy + r * .04),
        ink);
    canvas.drawCircle(top.center.translate(0, r * .02), r * .3, ink);
    canvas.drawCircle(top.center.translate(0, r * .02), r * .2,
        Paint()..color = Colors.white);
  }

  void _paint3D(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final f = r * 5; // distancia focal (perspectiva)
    final k = open.clamp(0.0, 1.15); // apertura (con rebote)
    final light = open.clamp(0.0, 1.0);
    final pitch = _pitch - (_pitch - .04) * light; // la cámara baja al abrir
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final cs = math.cos(spin), ss = math.sin(spin);
    // Como en el anime: la mitad de arriba SUBE y se inclina,
    // la de abajo se inclina hacia el frente.
    final lift = r * .72 * k;
    final ta = .42 * k, tb = .28 * k;
    final ca = math.cos(ta), sa = math.sin(ta);
    final cb = math.cos(tb), sb = math.sin(tb);

    Offset proj(double x, double y, double z, {bool roll = true}) {
      var x1 = x, y1 = y;
      if (roll) {
        x1 = x * cs - y * ss;
        y1 = x * ss + y * cs;
      }
      final yc = y1 * cp - z * sp;
      final zc = y1 * sp + z * cp;
      final q = f / (f - zc);
      return Offset(c.dx + x1 * q, c.dy - yc * q);
    }

    Offset pTop(double x, double y, double z, {bool roll = true}) =>
        proj(x, y * ca + z * sa + lift, -y * sa + z * ca, roll: roll);
    Offset pBot(double x, double y, double z) =>
        proj(x, y * cb - z * sb - lift * .06, y * sb + z * cb);

    // ---- muestreo de los dos hemisferios
    final top = <Offset>[];
    final bottom = <Offset>[];
    final rimT = <Offset>[];
    final rimB = <Offset>[];
    for (var j = 0; j < _lon; j++) {
      final b = j * 2 * math.pi / _lon;
      final cosB = math.cos(b), sinB = math.sin(b);
      for (var i = 0; i <= _lat; i++) {
        final a = i * (math.pi / 2) / _lat;
        final x = r * math.cos(a) * cosB;
        final h = r * math.sin(a);
        final z = r * math.cos(a) * sinB;
        top.add(pTop(x, h, z));
        bottom.add(pBot(x, -h, z));
        if (i == 0) {
          rimT.add(top.last);
          rimB.add(bottom.last);
        }
      }
    }

    final topHull = _hull(top);
    final band = r * .16;
    final silR = r * f / math.sqrt(f * f - r * r);
    final ballRect = Rect.fromCircle(center: c, radius: silR);

    final red = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6A55), Color(0xFFE3350D), Color(0xFF9E1B0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(topHull.getBounds());
    final bandPaint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = band;
    final outline = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = r * .05;

    final hl = pTop(-.38 * r, .78 * r, .5 * r, roll: false);
    final button = pTop(0, r * .02, r);

    // ================================================ CERRADA
    if (k < .001) {
      final sphere = Path()..addOval(ballRect);
      canvas.drawPath(sphere, Paint()..color = _white);
      canvas.drawPath(
          Path.combine(PathOperation.intersect, sphere, topHull), red);
      canvas.save();
      canvas.clipPath(sphere);
      canvas.drawPath(_arc(rimT, 0, _lon ~/ 2), bandPaint);
      canvas.restore();
      _button(canvas, button, r, glow);
      _shade(canvas, sphere, c, silR, hl, r);
      canvas.drawPath(sphere, outline..strokeWidth = r * .06);
      return;
    }

    // ================================================ ABIERTA
    final rimTPath = Path()..addPolygon(rimT, true);
    final rimBPath = Path()..addPolygon(rimB, true);
    final gap = Offset.lerp(rimTPath.getBounds().center,
        rimBPath.getBounds().center, .5)!;

    // 0) luz suave detrás (círculos sólidos semitransparentes)
    final halo = Paint();
    for (var n = 3; n >= 1; n--) {
      halo.color = const Color(0xFFDDEEFF).withValues(alpha: .07 * light * n);
      canvas.drawCircle(gap, r * (.6 + n * .45 * light), halo);
    }

    // 1) mitad de abajo (blanca) + su interior gris
    final bottomHull = _hull(bottom);
    canvas.drawPath(bottomHull, Paint()..color = _white);
    canvas.save();
    canvas.clipPath(bottomHull);
    canvas.drawCircle(
        c.translate(r * .35, r * .55), r * .9,
        Paint()..color = Colors.black.withValues(alpha: .10));
    canvas.restore();
    canvas.drawPath(
        rimBPath,
        Paint()
          ..color = Color.lerp(
              const Color(0xFFADB1BE), const Color(0xFFE6EEF9), light * .4)!);
    canvas.drawPath(bottomHull, outline);

    // 2) mitad de arriba (roja) — se ve su interior gris desde abajo
    canvas.drawPath(topHull, Paint()..color = const Color(0xFFE3350D));
    canvas.save();
    canvas.clipPath(topHull);
    canvas.drawCircle(
        hl.translate(r * .55, r * .5), r * .95,
        Paint()..color = const Color(0xFF9E1B0B).withValues(alpha: .45));
    canvas.drawCircle(
        hl, r * .3, Paint()..color = Colors.white.withValues(alpha: .35));
    canvas.restore();
    if (ta > pitch) {
      canvas.drawPath(
          rimTPath,
          Paint()
            ..color = Color.lerp(
                const Color(0xFFBDC1CC), const Color(0xFFE6EEF9), light * .3)!);
      canvas.drawPath(rimTPath, bandPaint);
    } else {
      canvas.save();
      canvas.clipPath(topHull);
      canvas.drawPath(_arc(rimT, 0, _lon ~/ 2), bandPaint);
      canvas.restore();
    }
    canvas.drawPath(topHull, outline);

    // 3) botón (va en la mitad de arriba, al frente)
    _button(canvas, button, r, glow);

    // 4) brillo pequeño entre las mitades
    if (light > .02) {
      canvas.drawOval(
        Rect.fromCenter(center: gap, width: r * 1.3 * light, height: r * .22 * light),
        Paint()..color = Colors.white.withValues(alpha: .55 * light),
      );
    }
  }

  /// Contorno convexo (Andrew monotone chain) → silueta de un hemisferio.
  static Path _hull(List<Offset> pts) {
    final p = [...pts]
      ..sort((a, b) =>
          a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    final lower = <Offset>[];
    for (final q in p) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, q) <= 0) {
        lower.removeLast();
      }
      lower.add(q);
    }
    final upper = <Offset>[];
    for (final q in p.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, q) <= 0) {
        upper.removeLast();
      }
      upper.add(q);
    }
    lower.removeLast();
    upper.removeLast();
    return Path()..addPolygon([...lower, ...upper], true);
  }

  static Path _arc(List<Offset> rim, int from, int to) {
    final path = Path()..moveTo(rim[from].dx, rim[from].dy);
    for (var i = from + 1; i <= to; i++) {
      path.lineTo(rim[i % rim.length].dx, rim[i % rim.length].dy);
    }
    return path;
  }

  /// Sombra esférica + brillo especular (da el volumen).
  static void _shade(Canvas canvas, Path shape, Offset c, double rad,
      Offset hl, double r,
      {bool highlight = true}) {
    final rect = Rect.fromCircle(center: c, radius: rad);
    canvas.drawPath(
      shape,
      Paint()
        ..shader = RadialGradient(
          center: Alignment((hl.dx - c.dx) / rad, (hl.dy - c.dy) / rad),
          radius: 1.25,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: .42),
          ],
          stops: const [.4, 1],
        ).createShader(rect),
    );
    if (!highlight) return;
    final h = Rect.fromCircle(center: hl, radius: r * .4);
    canvas.drawOval(
      h,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: .85),
          Colors.white.withValues(alpha: 0),
        ]).createShader(h),
    );
  }

  static void _button(Canvas canvas, Offset p, double r, double glow) {
    final squash = math.cos(_pitch);
    Rect ov(double rad) =>
        Rect.fromCenter(center: p, width: rad * 2, height: rad * 2 * squash);
    canvas.drawOval(ov(r * .3), Paint()..color = _ink);
    canvas.drawOval(
      ov(r * .21),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.4),
          colors: [Colors.white, Color(0xFFD5D8E0)],
        ).createShader(ov(r * .21)),
    );
    final g = glow.clamp(0.0, 1.0);
    if (g > 0) {
      canvas.drawOval(
          ov(r * .21), Paint()..color = const Color(0xFFFFE066).withValues(alpha: g));
      final halo = Rect.fromCircle(center: p, radius: r * .6);
      canvas.drawCircle(
        p,
        r * .6,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFE066).withValues(alpha: .65 * g),
            const Color(0xFFFFE066).withValues(alpha: 0),
          ]).createShader(halo),
      );
    }
    canvas.drawOval(
      ov(r * .12),
      Paint()
        ..color = const Color(0xFFC9CDD6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .03,
    );
  }

  @override
  bool shouldRepaint(covariant PokeBallPainter old) =>
      old.open != open || old.glow != glow || old.spin != spin;
}

/// Silueta de Poké Ball (decoración translúcida).
class PokeBallOutline extends StatelessWidget {
  final double size;
  final Color color;
  const PokeBallOutline({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _OutlinePainter(color)),
      );
}

class _OutlinePainter extends CustomPainter {
  final Color color;
  _OutlinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;
    final w = r * .14;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;

    canvas.drawCircle(c, r - w / 2, paint);
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx - r * .32, c.dy), paint);
    canvas.drawLine(Offset(c.dx + r * .32, c.dy), Offset(c.dx + r, c.dy), paint);
    canvas.drawCircle(c, r * .24, paint);
    canvas.drawCircle(c, r * .08, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _OutlinePainter old) => old.color != color;
}

/// Destellos que suben en el header. Se repinta solo con la animación
/// (repaint: loop) → no reconstruye ningún widget.
class _ParticlesPainter extends CustomPainter {
  final Animation<double> loop;
  _ParticlesPainter(this.loop) : super(repaint: loop);

  static final List<List<double>> _p = List.generate(30, (i) {
    final r = math.Random(i * 31 + 7);
    return [
      r.nextDouble(), // x
      r.nextDouble(), // y
      1.5 + r.nextDouble() * 3.5, // tamaño
      r.nextDouble(), // fase
      r.nextBool() ? 1.0 : 0.0, // ¿estrella?
    ];
  });
  static final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final v = loop.value;
    for (final p in _p) {
      final t = (v + p[3]) % 1;
      final x = p[0] * size.width;
      final y = ((p[1] - t * .35) % 1) * size.height;
      final a = .15 + .6 * (.5 + .5 * math.sin(2 * math.pi * (t * 3 + p[3])));
      _paint.color = Colors.white.withValues(alpha: a);
      if (p[4] == 1) {
        _drawStar(canvas, Offset(x, y), p[2] * 1.8, _paint);
      } else {
        canvas.drawCircle(Offset(x, y), p[2], _paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => false;
}