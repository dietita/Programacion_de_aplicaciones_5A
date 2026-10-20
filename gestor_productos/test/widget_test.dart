import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_productos/services/auth_service.dart';

void main() {
  test('Login compara con las variables', () {
    expect(AuthService.login('admin', '1234'), true);
    expect(AuthService.login('admin', 'mal'), false);
  });
}
