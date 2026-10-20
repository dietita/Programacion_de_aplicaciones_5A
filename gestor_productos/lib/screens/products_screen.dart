import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import 'detail_screen.dart';
import 'login_screen.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String usuario;
  const ProductsScreen({super.key, required this.usuario});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _service = ProductService();

  List<Product> _productos = [];
  bool _cargando = true;
  String? _error;

  // Búsqueda y filtro
  String _busqueda = '';
  String _categoria = 'Todas';

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  // LISTAR productos desde la API
  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _service.getProducts();
      setState(() => _productos = lista);
    } catch (e) {
      setState(() => _error = 'No se pudieron cargar los productos.\nRevisa tu conexión a internet.');
    } finally {
      setState(() => _cargando = false);
    }
  }

  // Categorías que existen en la lista
  List<String> get _categorias {
    final cats = _productos.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['Todas', ...cats];
  }

  // FILTRAR por texto y por categoría
  List<Product> get _productosFiltrados {
    return _productos.where((p) {
      final coincideTexto = p.title.toLowerCase().contains(_busqueda.toLowerCase());
      final coincideCategoria = _categoria == 'Todas' || p.category == _categoria;
      return coincideTexto && coincideCategoria;
    }).toList();
  }

  void _mensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: error ? Colors.red : null),
    );
  }

  // AGREGAR producto
  Future<void> _agregar() async {
    final nuevo = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (nuevo != null) {
      // La API siempre regresa id 21, así que le damos un id único local
      int maxId = 20;
      for (final p in _productos) {
        if (p.id > maxId) maxId = p.id;
      }
      final conId = Product(
        id: maxId + 1,
        title: nuevo.title,
        price: nuevo.price,
        description: nuevo.description,
        category: nuevo.category,
        image: nuevo.image,
      );
      setState(() => _productos.insert(0, conId));
      _mensaje('Producto agregado');
    }
  }

  // EDITAR producto
  Future<void> _editar(Product producto) async {
    final editado = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(producto: producto)),
    );
    if (editado != null) {
      setState(() {
        final i = _productos.indexWhere((p) => p.id == producto.id);
        if (i != -1) _productos[i] = editado;
      });
      _mensaje('Producto actualizado');
    }
  }

  // ELIMINAR producto (con confirmación)
  Future<void> _eliminar(Product producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${producto.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _service.deleteProduct(producto.id);
      setState(() => _productos.removeWhere((p) => p.id == producto.id));
      _mensaje('Producto eliminado');
    } catch (e) {
      _mensaje('No se pudo eliminar el producto', error: true);
    }
  }

  // VER DETALLES
  Future<void> _verDetalles(Product producto) async {
    final accion = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(producto: producto)),
    );
    if (accion == 'editar') _editar(producto);
    if (accion == 'eliminar') _eliminar(producto);
  }

  void _cerrarSesion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          Center(child: Text(widget.usuario)),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregar,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (texto) => setState(() => _busqueda = texto),
            ),
          ),

          // Filtro por categoría
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _categorias.map((cat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: _categoria == cat,
                    onSelected: (_) => setState(() => _categoria = cat),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(child: _contenido()),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton(onPressed: _cargarProductos, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final lista = _productosFiltrados;
    if (lista.isEmpty) {
      return const Center(child: Text('No se encontraron productos'));
    }

    // Grid responsivo: más columnas en pantallas más anchas
    return RefreshIndicator(
      onRefresh: _cargarProductos,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnas = (constraints.maxWidth / 220).floor().clamp(2, 6).toInt();
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnas,
              childAspectRatio: 0.62,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: lista.length,
            itemBuilder: (_, i) {
              final p = lista[i];
              return ProductCard(
                product: p,
                onTap: () => _verDetalles(p),
                onEdit: () => _editar(p),
                onDelete: () => _eliminar(p),
              );
            },
          );
        },
      ),
    );
  }
}
