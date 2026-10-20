import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

/// Formulario para AGREGAR o EDITAR un producto.
/// Si recibe un producto, está en modo edición.
class ProductFormScreen extends StatefulWidget {
  final Product? producto;
  const ProductFormScreen({super.key, this.producto});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _service = ProductService();

  final _tituloCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _imagenCtrl = TextEditingController();

  final List<String> _categorias = [
    "men's clothing",
    "women's clothing",
    'jewelery',
    'electronics',
  ];
  String? _categoria;
  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    // Si es edición, llenamos los campos con los datos actuales
    final p = widget.producto;
    if (p != null) {
      _tituloCtrl.text = p.title;
      _precioCtrl.text = p.price.toString();
      _descripcionCtrl.text = p.description;
      _imagenCtrl.text = p.image;
      _categoria = _categorias.contains(p.category) ? p.category : null;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final producto = Product(
      id: widget.producto?.id ?? 0,
      title: _tituloCtrl.text.trim(),
      price: double.parse(_precioCtrl.text.trim()),
      description: _descripcionCtrl.text.trim(),
      category: _categoria!,
      image: _imagenCtrl.text.trim(),
    );

    try {
      final resultado = _esEdicion
          ? await _service.updateProduct(producto)
          : await _service.addProduct(producto);
      if (!mounted) return;
      Navigator.pop(context, resultado);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el producto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _precioCtrl.dispose();
    _descripcionCtrl.dispose();
    _imagenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar producto' : 'Agregar producto')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Título
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El título es obligatorio';
                      }
                      if (valor.trim().length < 3) {
                        return 'Mínimo 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Precio
                  TextFormField(
                    controller: _precioCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'El precio es obligatorio';
                      }
                      final precio = double.tryParse(valor.trim());
                      if (precio == null) {
                        return 'Escribe un número válido (ej. 19.99)';
                      }
                      if (precio <= 0) {
                        return 'El precio debe ser mayor a 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Categoría
                  DropdownButtonFormField<String>(
                    value: _categoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categorias
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (valor) => setState(() => _categoria = valor),
                    validator: (valor) =>
                        valor == null ? 'Selecciona una categoría' : null,
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descripcionCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'La descripción es obligatoria';
                      }
                      if (valor.trim().length < 10) {
                        return 'Mínimo 10 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // URL de la imagen
                  TextFormField(
                    controller: _imagenCtrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL de la imagen',
                      prefixIcon: Icon(Icons.image),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'La URL de la imagen es obligatoria';
                      }
                      if (!valor.trim().startsWith('http')) {
                        return 'La URL debe empezar con http o https';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Vista previa de la imagen
                  if (_imagenCtrl.text.trim().startsWith('http'))
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.network(
                        _imagenCtrl.text.trim(),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Text('No se pudo cargar la imagen')),
                      ),
                    ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_esEdicion ? 'Guardar cambios' : 'Agregar producto'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
