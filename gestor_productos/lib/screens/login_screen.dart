import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'products_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  bool _ocultar = true;

  void _ingresar() {
    // 1. Validar que los campos no estén vacíos
    if (!_formKey.currentState!.validate()) return;

    // 2. Comparar los datos ingresados con los de las variables
    final usuario = _usuarioCtrl.text.trim();
    final contrasena = _contrasenaCtrl.text.trim();

    if (AuthService.login(usuario, contrasena)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProductsScreen(usuario: usuario)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario o contraseña incorrectos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront, size: 72, color: color),
                      const SizedBox(height: 8),
                      Text('Gestor de Productos',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                      const SizedBox(height: 4),
                      const Text('Inicia sesión para continuar',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),

                      // TextField usuario (no puede quedar vacío)
                      TextFormField(
                        controller: _usuarioCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'El usuario no puede estar vacío';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // TextField contraseña (no puede quedar vacío)
                      TextFormField(
                        controller: _contrasenaCtrl,
                        obscureText: _ocultar,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _ocultar = !_ocultar),
                          ),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'La contraseña no puede estar vacía';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _ingresar,
                          child: const Text('Ingresar', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text('¿No tienes cuenta? Regístrate'),
                      ),
                      const SizedBox(height: 8),
                      const Text('Prueba: admin / 1234',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
