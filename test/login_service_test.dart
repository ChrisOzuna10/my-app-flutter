import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/services/secure_storage_service.dart';

void main() {
  group('SecureStorageService credential validation', () {
    test('accepts the configured demo credentials', () {
      expect(
        SecureStorageService.credentialsMatch(
          'alumno@upchiapas.edu.mx',
          '123456789',
          'alumno@upchiapas.edu.mx',
          '123456789',
        ),
        isTrue,
      );
    });

    test('rejects wrong password', () {
      expect(
        SecureStorageService.credentialsMatch(
          'alumno@upchiapas.edu.mx',
          'wrong-password',
          'alumno@upchiapas.edu.mx',
          '123456789',
        ),
        isFalse,
      );
    });
  });
}
