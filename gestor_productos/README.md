# Gestor de Productos — Segunda parcial

App en Flutter que consume la API https://fakestoreapi.com/products/

Usuario de prueba: **admin** / **1234** (o registra uno nuevo).

## Estructura
```
lib/
├── main.dart                       -> arranque y tema
├── models/product.dart             -> clase Product (fromJson / toJson)
├── services/
│   ├── product_service.dart        -> GET, POST, PUT, DELETE con Dio
│   └── auth_service.dart           -> usuarios guardados en variables
├── screens/
│   ├── login_screen.dart           -> UI Inicio de sesión (validación + comparación)
│   ├── register_screen.dart        -> registro de usuarios
│   ├── products_screen.dart        -> UI Productos (cards, búsqueda, filtro, agregar/editar/eliminar)
│   ├── detail_screen.dart          -> UI Detalles
│   └── product_form_screen.dart    -> formulario agregar/editar con validaciones
└── widgets/product_card.dart       -> card de cada producto
```

## Correr
```
flutter create . --project-name gestor_productos
flutter pub get
flutter run
```
