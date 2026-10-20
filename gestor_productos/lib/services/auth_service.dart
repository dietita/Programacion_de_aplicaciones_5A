/// Control de acceso de la app.
/// Guarda los usuarios en variables (en memoria).
class AuthService {
  // Usuario por defecto para entrar a la app
  static const String usuarioValido = 'admin';
  static const String contrasenaValida = '1234';

  // Usuarios que se registran desde la pantalla de registro
  static final Map<String, String> _usuarios = {
    usuarioValido: contrasenaValida,
  };

  /// Compara lo que escribió el usuario con los datos guardados.
  static bool login(String usuario, String contrasena) {
    return _usuarios[usuario] == contrasena;
  }

  /// Registra un usuario nuevo. Regresa false si ya existe.
  static bool registrar(String usuario, String contrasena) {
    if (_usuarios.containsKey(usuario)) return false;
    _usuarios[usuario] = contrasena;
    return true;
  }
}
