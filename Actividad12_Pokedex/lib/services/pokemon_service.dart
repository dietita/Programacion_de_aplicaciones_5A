import 'package:dio/dio.dart';
import '../models/pokemon.dart';

/// Servicio que realiza las peticiones de red a la PokeAPI usando Dio.
class PokemonService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://pokeapi.co/api/v2/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// GET https://pokeapi.co/api/v2/pokemon/{idOrName}/
  Future<Pokemon> getPokemon(String idOrName) async {
    try {
      final response = await _dio.get('pokemon/${idOrName.toLowerCase()}/');
      if (response.statusCode == 200) {
        return Pokemon.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Error ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('No se encontró el Pokémon "$idOrName"');
      }
      throw Exception('Error de conexión: ${e.message}');
    }
  }

  /// GET https://pokeapi.co/api/v2/pokemon?limit=151
  Future<List<PokemonListItem>> getPokemonList({int limit = 151}) async {
    try {
      final response = await _dio.get(
        'pokemon',
        queryParameters: {'limit': limit, 'offset': 0},
      );
      final results = response.data['results'] as List;
      return results
          .map((e) => PokemonListItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error de conexión: ${e.message}');
    }
  }
}
