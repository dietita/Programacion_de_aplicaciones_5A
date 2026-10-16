# Pokédex — Flutter consumiendo una API

**Actividad 12 · Práctica académica 02**  
Alumno: César Daniel Santiago Servín — ITS Colima

App en Flutter que consume la [PokeAPI](https://pokeapi.co/api/v2/pokemon/1/) usando el paquete **Dio**.

## Qué cumple
1. **Dio en `pubspec.yaml`** → sección `dependencies`.
2. **Petición de red** → `lib/services/pokemon_service.dart` (`Future`, `dio.get`).
3. **Respuesta → clase Dart** → `lib/models/pokemon.dart` (`Pokemon.fromJson`).
4. **Obtener y mostrar datos** → `FutureBuilder` en `lib/screens/home_screen.dart` y `lib/screens/detail_screen.dart`.

## Estructura
```
lib/
├── main.dart
├── models/pokemon.dart
├── services/pokemon_service.dart
├── screens/home_screen.dart
├── screens/detail_screen.dart
├── widgets/ (pokemon_card, type_chip, pokeball_painter)
└── utils/type_colors.dart
```

## Ejecutar
```bash
flutter create . --project-name pokedex_app
flutter pub get
flutter run
```
