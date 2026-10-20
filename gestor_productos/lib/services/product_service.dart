import 'package:dio/dio.dart';
import '../models/product.dart';

/// Servicio que se comunica con la API https://fakestoreapi.com/products/
class ProductService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://fakestoreapi.com'));

  // LISTAR: GET /products
  Future<List<Product>> getProducts() async {
    final response = await _dio.get('/products');
    final List data = response.data;
    return data.map((item) => Product.fromJson(item)).toList();
  }

  // AGREGAR: POST /products
  Future<Product> addProduct(Product product) async {
    final response = await _dio.post('/products', data: product.toJson());
    return Product.fromJson(response.data);
  }

  // La FakeStoreAPI solo tiene 20 productos (id 1 al 20) y no guarda los
  // productos nuevos. Si el id es mayor a 20, el producto se creó en la app
  // y solo existe en la lista local, por eso no se manda a la API.
  bool _existeEnApi(int id) => id >= 1 && id <= 20;

  // EDITAR: PUT /products/{id}
  Future<Product> updateProduct(Product product) async {
    if (!_existeEnApi(product.id)) return product;
    final response =
        await _dio.put('/products/${product.id}', data: product.toJson());
    // La API regresa el producto editado; conservamos el id original.
    final editado = Product.fromJson(response.data);
    return Product(
      id: product.id,
      title: editado.title,
      price: editado.price,
      description: editado.description,
      category: editado.category,
      image: editado.image,
    );
  }

  // ELIMINAR: DELETE /products/{id}
  Future<void> deleteProduct(int id) async {
    if (!_existeEnApi(id)) return;
    await _dio.delete('/products/$id');
  }
}
