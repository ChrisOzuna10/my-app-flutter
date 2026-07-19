import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/services/secure_storage_service.dart';

void main() {
  group('SecureStorageService demo payload', () {
    test('builds the default demo values for the sensitive fields', () {
      final data = SecureStorageService.buildDemoSensitiveData(userId: 'student-user-001');

      expect(data['email'], 'alumno@upchiapas.edu.mx');
      expect(data['password'], '123456789');
      expect(data['jwt_token'], isNotEmpty);
      expect(data['api_key'], isNotEmpty);
      expect(data['user_id'], 'student-user-001');
    });
  });
}
