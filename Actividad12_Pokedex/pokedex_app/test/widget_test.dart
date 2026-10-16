import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/models/pokemon.dart';

void main() {
  test('PokemonListItem obtiene el id desde la url', () {
    final item = PokemonListItem.fromJson({
      'name': 'bulbasaur',
      'url': 'https://pokeapi.co/api/v2/pokemon/1/',
    });
    expect(item.id, 1);
    expect(item.displayName, 'Bulbasaur');
    expect(item.number, '#0001');
  });
}
